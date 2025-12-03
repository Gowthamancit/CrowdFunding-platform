Go to Remix IDE.
1. Create a file named CrowdFunding.sol and paste the code from the file.
2. Click the "Solidity Compiler" tab and click Compile.
3. Click the "Deploy & Run Transactions" tab.
4. Change "Environment" to Injected Provider - MetaMask.
5. Click Deploy. MetaMask will pop up; confirm the transaction (this costs fake gas).


Testing the Refund Scenario
To verify the logic works without waiting weeks for a deadline:
1. Deploy the contract.
2. Create a Campaign with a short deadline (e.g., current_timestamp + 300 for 5 minutes).
3. Set a high Target (e.g., 100 ETH).Donate a small amount (e.g., 0.1 ETH).Wait 5 minutes.
4. Try to Withdraw (as the owner) $\rightarrow$ Should fail (Target not met).
5. Try to Refund (as the donor) $\rightarrow$ Should succeed (Deadline passed + Target not met).
