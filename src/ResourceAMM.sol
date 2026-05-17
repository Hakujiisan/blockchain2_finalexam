// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LPToken is ERC20 {
    address public immutable amm;

    constructor() ERC20("GameFi LP", "GLP") {
        amm = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == amm);
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == amm);
        _burn(from, amount);
    }
}

contract ResourceAMM is ReentrancyGuard {
    using SafeERC20 for IERC20;

    IERC20 public immutable token0;
    IERC20 public immutable token1;
    LPToken public immutable lpToken;

    uint256 public reserve0;
    uint256 public reserve1;
    uint256 public constant FEE = 3; // 0.3%

    event Swap(address indexed trader, address tokenIn, uint256 amountIn, uint256 amountOut);
    event LiquidityAdded(address indexed provider, uint256 amount0, uint256 amount1, uint256 lpMinted);
    event LiquidityRemoved(address indexed provider, uint256 amount0, uint256 amount1, uint256 lpBurned);

    constructor(address _token0, address _token1) {
        token0 = IERC20(_token0);
        token1 = IERC20(_token1);
        lpToken = new LPToken();
    }

    function addLiquidity(uint256 amount0, uint256 amount1) external nonReentrant returns (uint256 lpMinted) {
        token0.safeTransferFrom(msg.sender, address(this), amount0);
        token1.safeTransferFrom(msg.sender, address(this), amount1);

        uint256 totalSupply = lpToken.totalSupply();
        if (totalSupply == 0) {
            lpMinted = _sqrt(amount0 * amount1);
        } else {
            lpMinted = _min((amount0 * totalSupply) / reserve0, (amount1 * totalSupply) / reserve1);
        }
        require(lpMinted > 0, "Insufficient liquidity minted");
        reserve0 += amount0;
        reserve1 += amount1;
        lpToken.mint(msg.sender, lpMinted);
        emit LiquidityAdded(msg.sender, amount0, amount1, lpMinted);
    }

    function removeLiquidity(uint256 lpAmount) external nonReentrant returns (uint256 amount0, uint256 amount1) {
        uint256 totalSupply = lpToken.totalSupply();
        amount0 = (lpAmount * reserve0) / totalSupply;
        amount1 = (lpAmount * reserve1) / totalSupply;
        require(amount0 > 0 && amount1 > 0, "Insufficient amounts");
        lpToken.burn(msg.sender, lpAmount);
        reserve0 -= amount0;
        reserve1 -= amount1;
        token0.safeTransfer(msg.sender, amount0);
        token1.safeTransfer(msg.sender, amount1);
        emit LiquidityRemoved(msg.sender, amount0, amount1, lpAmount);
    }

    function swap(address tokenIn, uint256 amountIn, uint256 minAmountOut)
        external
        nonReentrant
        returns (uint256 amountOut)
    {
        require(tokenIn == address(token0) || tokenIn == address(token1), "Invalid token");
        bool isToken0 = tokenIn == address(token0);
        (uint256 reserveIn, uint256 reserveOut) = isToken0 ? (reserve0, reserve1) : (reserve1, reserve0);

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 amountInWithFee = amountIn * (1000 - FEE);
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
        require(amountOut >= minAmountOut, "Slippage exceeded");

        if (isToken0) {
            reserve0 += amountIn;
            reserve1 -= amountOut;
            token1.safeTransfer(msg.sender, amountOut);
        } else {
            reserve1 += amountIn;
            reserve0 -= amountOut;
            token0.safeTransfer(msg.sender, amountOut);
        }
        emit Swap(msg.sender, tokenIn, amountIn, amountOut);
    }

    function getAmountOut(address tokenIn, uint256 amountIn) public view returns (uint256) {
        bool isToken0 = tokenIn == address(token0);
        (uint256 reserveIn, uint256 reserveOut) = isToken0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint256 amountInWithFee = amountIn * (1000 - FEE);
        return (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
    }

    function _sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) y = z;
        z = (x / z + z) / 2;
        return y;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
