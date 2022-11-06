// SPDX-License-Identifier: MIT

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint);

    function price1CumulativeLast() external view returns (uint);

    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);

    function burn(address to) external returns (uint amount0, uint amount1);

    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract TradeCoin {
    function balanceOf(address account) virtual view public returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) virtual public returns (bool);

    function approve(address _spender, uint256 _value) virtual public returns (bool);
}

abstract contract IWant {
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);

    function totalSupply() external view virtual returns (uint256);

    function balanceOf(address _account) virtual view public returns (uint256);

    function transfer(address _to, uint256 _value) external virtual returns (bool);

    function approve(address _spender, uint256 _value) external virtual returns (bool);
}


abstract contract IGM {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function tokenOfOwner(address _owner) public view virtual returns (uint[] memory);
}

interface IStake {
    function stake(uint _num, address to) external;
}


contract WantSale is Ownable {

    address public wantAddr;
    address public tradeCoinAddr;
    address public receiverAddr;
    address public pairAddr;
    address public stakeAddr;

    IGM public gm;
    TradeCoin private tc;
    IWant private want;
    IUniswapV2Router01 public uniswapV2Router;
    IPancakePair private pair;
    IStake private stake;

    uint256 private WantPriceTradeCoin;
    uint256 private WantBuyCount = 500 * 1 ether;

    uint256 private PeriodStartGmId;
    uint256 private PeriodEndGmId;
    uint256 private PeriodStartSaleHeight;
    uint256 private PeriodEndSaleHeight;

    mapping(uint256 => uint256) private countOfGmIdBuyWant;

    event BuyWant(address _from, uint256 _count);

    constructor(){}

    function setGMAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        gm = IGM(_addr);
    }

    function setWantAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        wantAddr = _addr;
        want = IWant(_addr);
    }

    function setTradeCoinAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        tradeCoinAddr = _addr;
        tc = TradeCoin(_addr);
    }

    function setReceiverAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        receiverAddr = _addr;
    }

    function setUniswapV2RouterAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        uniswapV2Router = IUniswapV2Router01(_addr);
    }

    function setPairAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        pairAddr = _addr;
        pair = IPancakePair(_addr);
    }

    function setStakeAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        stakeAddr = _addr;
        stake = IStake(_addr);
    }

    function setWantPriceTradeCoin(uint256 _price) external onlyOwner {
        WantPriceTradeCoin = _price;
    }

    function setWantBuyCount(uint256 _count) external onlyOwner {
        WantBuyCount = _count;
    }

    function setPeriodConf(uint256 _startGmId, uint256 _endGmId, uint256 _startHeight, uint256 _endHeight) external onlyOwner {
        PeriodStartGmId = _startGmId;
        PeriodEndGmId = _endGmId;
        PeriodStartSaleHeight = _startHeight;
        PeriodEndSaleHeight = _endHeight;
    }

    function getPeriodConf() external view returns (uint256 _startGmId, uint256 _endGmId, uint256 _startHeight, uint256 _endHeight) {
        return (PeriodStartGmId, PeriodEndGmId, PeriodStartSaleHeight, PeriodEndSaleHeight);
    }

    function buy(uint256 _count) external {
        require(block.number >= PeriodStartSaleHeight && block.number <= PeriodEndSaleHeight, "not sale time");
        require(want.balanceOf(address(this)) >= _count, "Error: WanT not enough");
        require(tc.balanceOf(msg.sender) >= WantPriceTradeCoin * _count / (1 ether), "Error: usdt balance not enough");

        uint[] memory gmIds = gm.tokenOfOwner(msg.sender);
        (uint _remain,) = getBuyCount();
        require(_remain >= _count, "over max count");
        uint256 _tmp = _count;
        for (uint i = 0; i < gmIds.length; i++) {
            if (_tmp == 0) {
                break;
            }
            uint256 def = WantBuyCount - countOfGmIdBuyWant[gmIds[i]];
            if (gmIds[i] >= PeriodStartGmId && gmIds[i] <= PeriodEndGmId && def > 0) {
                if (_tmp > def) {
                    _tmp -= def;
                    countOfGmIdBuyWant[gmIds[i]] += def;
                } else {
                    countOfGmIdBuyWant[gmIds[i]] += _tmp;
                    _tmp = 0;
                }
            }
        }

        tc.transferFrom(msg.sender, receiverAddr, WantPriceTradeCoin * _count / (1 ether));

        (uint reserveA, uint reserveB,) = pair.getReserves();
        uint _li = 0;
        if (wantAddr == pair.token0()) {
            tc.transferFrom(msg.sender, address(this), _count * reserveB / reserveA);
            _li = _addLiq(_count, _count * reserveB / reserveA, 0, 0, address(this));
        } else {
            tc.transferFrom(msg.sender, address(this), _count * reserveA / reserveB);
            _li = _addLiq(_count, _count * reserveA / reserveB, 0, 0, address(this));
        }

        pair.approve(stakeAddr, _li);
        stake.stake(_li, msg.sender);
        emit BuyWant(msg.sender, _count);
    }

    function getAddLiq(uint _count) external view returns (uint r1, uint r2){
        (uint reserveA, uint reserveB,) = pair.getReserves();
        if (wantAddr < tradeCoinAddr) {
            return (_count, _count * reserveB / reserveA);
        }
        return (_count, _count * reserveA / reserveB);
    }

    function _addLiq(uint256 _a1, uint256 _a2, uint256 _b1, uint256 _b2, address _to) internal returns (uint _li) {
        want.approve(address(uniswapV2Router), _a1);
        tc.approve(address(uniswapV2Router), _a2);
        (,, _li) = uniswapV2Router.addLiquidity(wantAddr, tradeCoinAddr, _a1, _a2, _b1, _b2, _to, block.timestamp);
    }

    function getBuyCount() public view returns (uint256 _remain, uint _total) {
        uint[] memory gmIds = gm.tokenOfOwner(msg.sender);
        for (uint i = 0; i < gmIds.length; i++) {
            uint256 def = WantBuyCount - countOfGmIdBuyWant[gmIds[i]];
            if (gmIds[i] >= PeriodStartGmId && gmIds[i] <= PeriodEndGmId && def > 0) {
                _total += WantBuyCount;
                _remain += def;
            }
        }
        return (_remain, _total);
    }

    function getCountByGmId(uint256 _gmId) external view returns (uint256 _count) {
        return countOfGmIdBuyWant[_gmId];
    }
}