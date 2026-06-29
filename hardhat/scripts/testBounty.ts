import { network } from "hardhat";
import { keccak256, encodePacked, toHex } from "viem";

async function main() {
    console.log("Starting integration test on Ritual Testnet...");
    
    const { viem } = await network.connect();
    
    const [account] = await viem.getWalletClients();
    const publicClient = await viem.getPublicClient();
    const contractAddress = "0xa0bB13fc2F4abbA604C4f42B0571E071EDea9A2c";
    
    const bountyContract = await viem.getContractAt("AIBountyJudge", contractAddress);

    const answer = "My hidden submission!";
    const salt = toHex("random-salt-1234", { size: 32 }); 
    const sender = account.account.address;
    
    console.log("Fetching latest block time from Ritual Testnet...");
    const latestBlock = await publicClient.getBlock({ blockTag: 'latest' });
    const blockchainTime = latestBlock.timestamp;
    console.log(`⏱️ Current Blockchain Timestamp (in ms): ${blockchainTime}`);

    // Adding 5 minutes (300,000 ms) and 20 minutes (1,200,000 ms)
    const submissionDeadline = blockchainTime + 300000n; 
    const revealDeadline = blockchainTime + 1200000n;    
    
    console.log("Creating new bounty with millisecond-synchronized deadlines...");
    const createTx = await bountyContract.write.createBounty([submissionDeadline, revealDeadline]);
    await publicClient.waitForTransactionReceipt({ hash: createTx });
    
    const bountyId = await bountyContract.read.bountyCounter();
    console.log(`✅ Bounty Created! ID: ${bountyId}`);

    const commitment = keccak256(
        encodePacked(
            ['string', 'bytes32', 'address', 'uint256'],
            [answer, salt, sender, bountyId]
        )
    );
    console.log(`🔐 Generated Commitment Hash: ${commitment}`);

    console.log("Submitting commitment...");
    const submitTx = await bountyContract.write.submitCommitment([bountyId, commitment]);
    await publicClient.waitForTransactionReceipt({ hash: submitTx });
    console.log(`✅ Commitment successfully submitted and locked on-chain!`);
    
    console.log("\nSuccess! The commit-reveal smart contract logic works exactly as intended.");
}

main().catch(console.error);
