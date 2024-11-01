# Rareskills Week 01 Assignment

## ERC777

### Observations

- `ERC777` is not part of OZ codebase starting `v5.x`
- if `account` is a contract, it must implement the {IERC777Recipient} interface.
  - if using `send` or `operatorSend` and `transferFrom` don't require it
  - backward compatibility since `transfer`
- deploying ERC777 in a testnet env requires ERC1820 also being deployed
  - best is to `vm.fork`

### Questions

- Update existing ERC20 with ERC777, is that possible?
- vs code complains about my inheritdoc natspec comment

### Open Challenges

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
