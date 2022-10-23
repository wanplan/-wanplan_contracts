// SPDX-License-Identifier: MIT



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
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
    function transferFrom(address sender, address recipient, uint256 amount) virtual public returns (bool);

    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address _account) virtual view public returns (uint256);

    function transfer(address _to, uint256 _value) public virtual returns (bool);

}


abstract contract IGM {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function tokenOfOwner(address _owner) public view virtual returns (uint[] memory);
}


contract WantSale is Ownable {

    using SafeMath for uint256;

    address public GMAddr;
    address public WantAddr;
    address public TradeCoinAddr;
    address public ReceiverAddr;

    IGM private gm;
    TradeCoin private tc;
    IWant private want;

    uint256 private WantPriceTradeCoin;
    uint256 private WantBuyCount = 500 * 1 ether;

    uint256 private PeriodStartGmId;
    uint256 private PeriodEndGmId;
    uint256 private PeriodStartSaleHeight;
    uint256 private PeriodEndSaleHeight;

    bool public PublicBuy;

    mapping(uint256 => uint256) private countOfGmIdBuyWant;

    event BuyWant(address _from, uint256 _count);

    constructor(){}

    function setGMAddr(address _addr) onlyOwner public {
        GMAddr = _addr;
        gm = IGM(_addr);
    }

    function setWantAddr(address _addr) onlyOwner public {
        WantAddr = _addr;
        want = IWant(_addr);
    }

    function setTradeCoinAddr(address _addr) onlyOwner public {
        TradeCoinAddr = _addr;
        tc = TradeCoin(_addr);
    }

    function setReceiverAddr(address _addr) onlyOwner public {
        ReceiverAddr = _addr;
    }

    function setWantPriceTradeCoin(uint256 _price) onlyOwner public {
        WantPriceTradeCoin = _price;
    }

    function setWantBuyCount(uint256 _count) onlyOwner public {
        WantBuyCount = _count;
    }

    function setPeriodConf(uint256 _startGmId, uint256 _endGmId, uint256 _startHeight, uint256 _endHeight) onlyOwner public {
        PeriodStartGmId = _startGmId;
        PeriodEndGmId = _endGmId;
        PeriodStartSaleHeight = _startHeight;
        PeriodEndSaleHeight = _endHeight;
    }

    function getPeriodConf() public view returns (uint256 _startGmId, uint256 _endGmId, uint256 _startHeight, uint256 _endHeight) {
        return (PeriodStartGmId, PeriodEndGmId, PeriodStartSaleHeight, PeriodEndSaleHeight);
    }

    function buy(uint256 _count) public payable {
        require(want.balanceOf(address(this)) >= _count, "Error: WanT not enough");
        require(tc.balanceOf(msg.sender) >= WantPriceTradeCoin.mul(_count) / (1 ether), "Error: usdt balance not enough");
        if (!PublicBuy) {
            uint[] memory gmIds = gm.tokenOfOwner(msg.sender);
            uint256 _tmp = _count;
            for (uint i = 0; i < gmIds.length; i++) {
                if (_tmp == 0) {
                    break;
                }
                uint256 def = WantBuyCount - countOfGmIdBuyWant[gmIds[i]];
                if (gmIds[i] >= PeriodStartGmId && gmIds[i] <= PeriodEndGmId &&  def > 0) {
                    if (_tmp > def) {
                        _tmp -= def;
                        countOfGmIdBuyWant[gmIds[i]] += def;
                    } else {
                        countOfGmIdBuyWant[gmIds[i]] += _tmp;
                        _tmp = 0;
                    }
                }
            }

            tc.transferFrom(msg.sender, ReceiverAddr, WantPriceTradeCoin.mul(_count) / (1 ether));
            want.transfer(msg.sender, _count);
        } else {
            want.transfer(msg.sender, _count);
        }

        emit BuyWant(msg.sender, _count);
    }

    function getBuyCount() public view returns (uint256 _remain, uint _total) {
        uint[] memory gmIds = gm.tokenOfOwner(msg.sender);
        for (uint i = 0; i < gmIds.length; i++) {
            uint256 def = WantBuyCount - countOfGmIdBuyWant[gmIds[i]];
            if (gmIds[i] >= PeriodStartGmId && gmIds[i] <= PeriodEndGmId &&  def > 0) {
                _total += WantBuyCount;
                _remain += def;
            }
        }
        return (_remain, _total);
    }
}