/**
 *  1. order (input, minOut), (maxInput, output)
 *  buy(x token, pay max y payment token)
 *  buy(min x token, pay y payment token)
 *  sell(x token, receive min y payment token)
 *  sell(max x token, receive y payment token)
 *  2. slippage (general price impact)
 *  3. rate limiting
 *  4. TWAP
 */

// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC1363} from "@openzeppelin/contracts@5.1.0/token/ERC20/extensions/ERC1363.sol";
import {IERC136} from "@openzeppelin/contracts@5.1.0/interfaces/IERC1363.sol";
import {IERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts@5.1.0/token/ERC20/ERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts@5.1.0/access/Ownable2Step.sol";

contract ERC1363Bonding is ERC1363 {
    IERC1363 public paymentToken;

    uint256 public constant SLOPE = 1;
    uint256 public constant PRECISION = 10e18;

    error TooMuchSlippage();
    error TransferPaymentFromCustomerFailed();

    constructor(string memory name_, string memory symbol_) Ownable(msg.sender) ERC20(name_, symbol_) {}

    // buy(x token, pay max y payment token)
    function buy(uint256 tokenOut, uint256 maxPaymentTokenIn) external {
        (uint256 currentX, uint256 currentY, uint256 newX, uint256 newY) = computePointOnCurve(true, tokenOut);
        // add here price impact
        uint256 price = computePrice(true, currentX, currentY, newX, newY);
        if (price > maxPaymentTokenIn) revert TooMuchSlippage();

        bool success = transferFromAndCall(msg.sender, address(this), price);
        if (!success) TransferFromCustomerFailed();

        _mint(msg.sender, amountTokenIssued);
    }

    // buy(min x token, pay y payment token)
    function buyMin(uint256 minTokenOut, uint256 paymentTokenIn) external {
        uint256 amountTokenIssued = computeEmissionBasedOnDesiredPrice(true, paymentTokenIn);
        if (amountTokenIssued < minTokenOut) revert TooMuchSlippage();

        bool sucess = transferFromAndCall(msg.sender, address(this), paymentTokenIn);
        if (!success) TransferFromCustomerFailed();

        _mint(msg.sender, amountTokenIssued);
    }

    // sell(x token, receive min y payment token)
    function sell(uint256 tokenIn, uint256 minPaymentTokenOut) external {}

    // sell(max x token, receive y payment token)
    function sellMax(uint256 maxTokenIn, uint256 paymentTokenOut) external {}

    function computePointOnCurve(bool isGrowing, uint256 deltaAmount)
        internal
        view
        returns (uint256 currentX, uint256 currentY, uint256 newX, uint256 newY)
    {
        currentX = totalSupply();
        currentY = currentX;
        if (isGrowing) {
            newX = currentX + deltaAmount;
            newY = newX;
        } else {
            newX = currentX - deltaAmount;
            newY = newX;
        }
    }

    function computePrice(bool isGrowing, uint256 currentX, uint256 currentY, uint256 newX, uint256 newY)
        internal
        returns (uint256)
    {
        if (isGrowing) {
            return (newY * newX - currentY * currentX) / (2 * PRECISION);
        } else {
            return (currentY * currentX - newY * newX) / (2 * PRECISION);
        }
    }

    // given: suggestedDelta = paymentToken = dy
    // desired: change in supply = dx
    function computeEmissionBasedOnDesiredPrice(bool isGrowing, uint256 suggestedDelta) internal returns (uint256) {
        uint256 currentX = totalSupply();
        if (isGrowing) {
            // sqrt(2*out + totalSupply^2) = newTotalSupply
            // TODO missing SQRT
            uint256 newX = (2 * (suggestedDelta + currentX) * (suggestedDelta + currentX)) / PRECISION;
            uint256 amountTokenIssued = newX - currentX;
        } else {
            // TODO missing SQRT
            uint256 newX = (currentX**2 - 2 * )
        }
    }
}

/**
 * out = (y1*x1 - y0*x0) / 2
 * 2*out = y1x1 - totalSupply^2
 * 2*out + totalSupply^2 = newTotalSupply^2
 *
 * sqrt(2*out + totalSupply^2) = newTotalSupply

 out = (y0x0 - y1x1) / 2
 2 * out = totalSupply^2 - newSupply^2
 newSupply^2 = totalSupply^2 - 2*out
 newSupply = sqrt(totalSupply^2 - 2*out)
 */
