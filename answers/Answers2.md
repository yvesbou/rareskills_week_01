Why does the SafeERC20 program exist and when should it be used?

## Allowances

`safeIncreaseAllowance` and `safeDecreaseAllowance` prevent the silent failures of `approve` function of certain tokens + it prevents the double spending (I dont understand it, see example below)

```Solidity
function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }
```

// Starting allowance: 100

bob: Can be frontrun (get 100)
tx1: approve(0)  
tx2: approve(50)
bob: Can get 50 -> allowance fully used

// Bob could get 150 total (100 + 50)

// Starting allowance: 100
bob: (frontrun get 100)
tx: safeDecreaseAllowance(50) // Reads 100, sets to 50
bob: Can get 50 -> allowance fully used
// Bob can frontrun and get 100
// bob got 150 as well

## Transfers

`using SafeERC20 for IERC20;` to make tx revert if transfers are not successful (prevent silent failures)
