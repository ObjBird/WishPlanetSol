const DataToZeroAddress = artifacts.require("DataToZeroAddress");

module.exports = async function (deployer, network, accounts) {
  console.log("=".repeat(50));
  console.log(`Deploying to network: ${network}`);
  console.log(`Deploying from account: ${accounts[0]}`);
  console.log("=".repeat(50));

  try {
    // Deploy the contract
    await deployer.deploy(DataToZeroAddress);

    // Get the deployed instance
    const instance = await DataToZeroAddress.deployed();

    console.log("✅ DataToZeroAddress deployed successfully!");
    console.log(`📍 Contract address: ${instance.address}`);
    console.log(`🌐 Network: ${network}`);
    console.log(`👤 Deployed by: ${accounts[0]}`);

    // Save deployment info to console for easy access
    console.log("\n" + "=".repeat(50));
    console.log("DEPLOYMENT SUMMARY");
    console.log("=".repeat(50));
    console.log(`Contract: DataToZeroAddress`);
    console.log(`Address: ${instance.address}`);
    console.log(`Network: ${network}`);
    console.log(`Deployer: ${accounts[0]}`);
    console.log(`Transaction hash: ${instance.transactionHash}`);
    console.log("=".repeat(50));

  } catch (error) {
    console.error("❌ Deployment failed:");
    console.error(error);
    throw error;
  }
};
