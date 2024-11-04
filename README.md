# Rareskills Week 01 Assignment

## ERC777

### Observations

- If multiple tokens have the same interface hash `"ERC777TokensRecipient"` a malicious user can set the interface
- `ERC777` is not part of OZ codebase starting `v5.x`
- if `account` is a contract, it must implement the {IERC777Recipient} interface.
  - if using `send` or `operatorSend` and `transferFrom` don't require it
  - backward compatibility since `transfer`
- deploying ERC777 in a testnet env requires ERC1820 also being deployed
  - best is to `vm.fork`
- owner of `ERC777` can decide to circumvent receiving hook for minting

### Questions

- Do operator face any restrictions on how to use the tokens?
- Update existing ERC20 with ERC777, is that possible?
  - yes, ERC777 is backwards compatible
- vs code complains about my inheritdoc natspec comment

### Open Challenges

## ERC-1363

### Observations

## Foundry with Soldeer Template

```shell
# to install the dependencies listed in foundry.toml
forge soldeer update
# build
forge build
# test
forge test

# remove dependencies
forge soldeer uninstall DEPENDENCY
# install dependencies
forge soldeer install @openzeppelin-contracts~5.0.2
```
