## Privacy-Preserving AI Bounty Judge Deliverables

### Reflection Question
In a well-designed bounty system, the bounty parameters, reward amounts, submission deadlines, and the final revealed answers should remain strictly public to ensure transparency and trust in the process. Conversely, participant submissions must stay securely hidden during the active submission phase to prevent unfair copying and maintain competitive integrity. Additionally, sensitive data like storage credentials or personally identifiable information should always be encrypted and kept strictly off-chain. When determining the outcome, Artificial Intelligence is best suited for objectively evaluating, scoring, and ranking all submitted answers in a single batch process against a predefined rubric. However, a human-in-the-loop, typically the bounty owner, should retain the final decision-making power to finalize the winner and authorize the payout. 

### Advanced Track: Ritual-Native Architecture Note
While a standard Commit-Reveal flow hides answers during submission, the plaintexts still become public *before* the AI judging phase. A Ritual-Native architecture solves this by keeping answers fully hidden until judging is entirely complete. 
*   **Submission:** Participants encrypt answers using a Ritual TEE public key. Only an encrypted reference (e.g., IPFS CID) is stored on-chain.
*   **Batch Judging:** The TEE pulls the encrypted references, decrypts them internally, and evaluates all answers in a single LLM batch request, preventing fragmented context.
*   **Final Output:** The TEE pushes a single `revealedAnswersHash` and the `winnerIndex` back to the smart contract, while publishing the plaintext bundle to IPFS for the human owner to verify and finalize.