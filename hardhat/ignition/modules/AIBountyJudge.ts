import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const AIBountyJudgeModule = buildModule("AIBountyJudgeModule", (m) => {
  // This matches the contract name inside your AIJudge.sol
  const aiBountyJudge = m.contract("AIBountyJudge");

  return { aiBountyJudge };
});

export default AIBountyJudgeModule;
