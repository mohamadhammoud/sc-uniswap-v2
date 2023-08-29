import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Uniswap", function () {
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    // Deplot Token A and B.
    const Token = await ethers.getContractFactory("Token");
    const tokenA = await Token.deploy("Token A", "A");
    const tokenB = await Token.deploy("Token B", "B");

    // Deploy Uniswap Factory
    const UniswapV2Factory = await ethers.getContractFactory(
      "UniswapV2Factory"
    );
    const uniswapV2Factory = await UniswapV2Factory.deploy();

    const UniswapV2Library = await ethers.getContractFactory(
      "UniswapV2Library"
    );
    const lib = await UniswapV2Library.deploy();

    // Deploy Uniswap Router
    const UniswapV2Router = await ethers.getContractFactory("UniswapV2Router", {
      libraries: {
        UniswapV2Library: await lib.getAddress(),
      },
    });
    const uniswapV2Router = await UniswapV2Router.deploy(
      await uniswapV2Factory.getAddress()
    );

    return {
      owner,
      otherAccount,
      tokenA,
      tokenB,
      uniswapV2Router,
      lib,
      uniswapV2Factory,
    };
  }

  describe("Deployment", function () {
    it("Should Add Liquidity", async function () {
      const {
        owner,
        otherAccount,
        tokenA,
        tokenB,
        uniswapV2Router,
        lib,
        uniswapV2Factory,
      } = await loadFixture(deployFixture);

      const oneMillionEther = ethers.parseEther("1000000");
      const halfMillionEther = ethers.parseEther("500000");

      await tokenA.mint(owner.address, oneMillionEther);
      await tokenB.mint(owner.address, halfMillionEther);

      expect(await tokenA.balanceOf(owner.address)).to.be.equal(
        oneMillionEther
      );

      expect(await tokenB.balanceOf(owner.address)).to.be.equal(
        halfMillionEther
      );

      const tokenA_address = await tokenA.getAddress();
      const tokenB_address = await tokenB.getAddress();
      const uniswapV2Router_address = await uniswapV2Router.getAddress();
      const uniswapV2Factory_address = await uniswapV2Factory.getAddress();

      await tokenA.approve(uniswapV2Router_address, ethers.MaxUint256);
      await tokenB.approve(uniswapV2Router_address, ethers.MaxUint256);

      await uniswapV2Router.addLiquidity(
        tokenA_address,
        tokenB_address,
        oneMillionEther,
        halfMillionEther,
        1,
        1,
        owner.address
      );

      const pair = await lib.pairFor(
        uniswapV2Factory_address,
        tokenA_address,
        tokenB_address
      );

      const UniswapV2Pair = await ethers.getContractFactory("UniswapV2Pair");
      const balance = await UniswapV2Pair.attach(pair).balanceOf(owner.address);

      const expectedLiquiditybalance = Math.sqrt(
        Number(oneMillionEther.toString()) * Number(halfMillionEther.toString())
      );

      expect(Number(balance.toString())).to.be.eq(
        Number(expectedLiquiditybalance.toString())
      );

      // Swapping
      await tokenA.mint(otherAccount.address, oneMillionEther);

      await tokenA
        .connect(otherAccount)
        .approve(uniswapV2Router_address, oneMillionEther);

      await uniswapV2Router
        .connect(otherAccount)
        .swapExactTokensForTokens(
          ethers.parseEther("1000"),
          ethers.parseEther("497"),
          [tokenA_address, tokenB_address],
          otherAccount.address
        );

      const otherAccountBalance = await tokenB.balanceOf(otherAccount.address);
      expect(otherAccountBalance).to.be.greaterThanOrEqual(
        ethers.parseEther("497")
      );

      // Remove Liquidity
      const ownerBalance = await UniswapV2Pair.attach(pair).balanceOf(
        owner.address
      );

      await UniswapV2Pair.attach(pair).approve(
        uniswapV2Router_address,
        ownerBalance
      );

      await uniswapV2Router.removeLiquidity(
        tokenA_address,
        tokenB_address,
        ownerBalance,
        ethers.parseEther("4000"),
        ethers.parseEther("2000"),
        owner.address
      );

      expect(
        await UniswapV2Pair.attach(pair).balanceOf(owner.address)
      ).to.be.equal(0);

      console.log(await tokenA.balanceOf(owner.address));
      console.log(await tokenB.balanceOf(owner.address));

      expect(await tokenA.balanceOf(owner.address)).to.be.greaterThanOrEqual(
        oneMillionEther
      );

      expect(await tokenA.balanceOf(owner.address)).to.be.greaterThan(0);
    });
  });
});
