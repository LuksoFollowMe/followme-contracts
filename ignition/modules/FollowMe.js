// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("FollowMeModule", (m) => {
	const follerContract = "0xf01103E5a9909Fc0DBe8166dA7085e0285daDDcA";

	const followMe = m.contract("FollowMe", [follerContract], {
		_followerContract: follerContract,
	});

	return { followMe };
});
