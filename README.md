# 🔐 Price-Locked ETH Vault

A **single-user ETH vault** smart contract that locks a user's deposited ETH and only allows withdrawal once the total USD value of the vault exceeds a **minimum threshold**.

---

## 🧩 Overview

This contract enables a one-at-a-time **exclusive ETH vault** that:

- Accepts ETH deposits from **a single user**.
- **Locks** the deposited ETH — no one else can use the vault until it's withdrawn.
- Uses a **Chainlink ETH/USD price feed** to determine when the ETH value has appreciated.
- Only allows withdrawal **when the USD value of the vault meets or exceeds a specified threshold**.

---

## 🛠️ Features

- ✅ **Single user access**: Only one user can interact with the vault at a time.
- 🔒 **Lock mechanism**: ETH is locked to that user until they withdraw.
- 💵 **USD valuation**: ETH value is converted to USD using a Chainlink oracle.
- ⛔ **Withdraw blocked** if value is below a set USD minimum.
- 🔁 Vault **unlocks after withdrawal**, allowing the next user to deposit.

---

## 📄 Contract Flow

1. **Deposit ETH**  
   - First user sends ETH to the contract.  
   - Contract locks itself to that user's address.

2. **Check Vault Value (USD)**  
   - The vault uses Chainlink’s ETH/USD price feed to calculate total USD value of ETH held.

3. **Withdraw ETH**  
   - Only the locked user can withdraw.  
   - Withdrawal only allowed if the vault's USD value ≥ `MINIMUM_VAULT_USD_WITHDRAWAL_VALUE`.

4. **Reset**  
   - After withdrawal, the vault is open to new users again.

---

## 🔧 Constructor Parameters

- `AggregatorV3Interface _priceFeed`: Chainlink price feed used to fetch ETH/USD price.

---