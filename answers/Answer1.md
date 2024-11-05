"Create a markdown file about what problems ERC777 and ERC1363 solves. Why was ERC1363 introduced, and what issues are there with ERC777?"

## Why ERC777 and ERC1363 where introduced

Standard ERC20 Tokens lack the ability to react to approving, sending or receiving tokens. This ability can be quite helpful to reject unwanted tokens, to trigger automated action based on some policy (like forwarding some tokens to a SAFE or creating a registry of contracts that sent tokens to a particular contract).

Moreover, it allows to improve the User Experience by allowing users to directly send tokens to a contract, instead of approve+transferFrom.

```Solidity
// user called approve before on the target contract
function deposit(uint256 amount) external {
    savingToken.transferFrom(msg.sender, address(this), amount);
}
```

## Issues with ERC777

ERC777 callbacks allow re-entrancy attacks. (so does ERC1363)

### Costlier and Operational Overhead

ERC777 to trigger the callback need to lookup the interface in the global ERC1820 registry, which costs additional gas to call another contract. And the additional overhead to register the contract in the ERC1820-registry.

### Dangerous overriding transfer & transferFrom

ERC777 overrides transfer and transferFrom and in them, it introduces the callback. Previously implemented contracts that called transfer or transferFrom on tokens would not expect re-entrancy.

## ERC1363

ERC1363 doesn't require the global ERC-1820 registry, thus saves gas.

Also ERC1363 introduces new functions approveAndCall, transferAndCall and transferFromAndCall and leaves ERC20 functions un-altered.
