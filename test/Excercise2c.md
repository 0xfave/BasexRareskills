# Best Pratice to follow

in the withdraw function the `internalBalances` should be updated before the transfer is done

it should check if the token is paused to prevent the contract functionality from failing
