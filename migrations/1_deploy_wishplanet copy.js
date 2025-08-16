const WishPlanet = artifacts.require("WishPlanet");

module.exports = function (deployer, network, accounts) {
    console.log("Deploying WishPlanet to network:", network);
    console.log("Deployer account:", accounts[0]);

    deployer.deploy(WishPlanet)
        .then(function (instance) {
            console.log("WishPlanet deployed at address:", instance.address);
            console.log("Contract owner:", accounts[0]);
            return instance;
        })
        .catch(function (error) {
            console.error("Deployment failed:", error);
        });
};
