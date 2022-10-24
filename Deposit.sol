// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

abstract contract ILPToken {
    function balanceOf(address account) virtual view public returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) virtual public returns (bool);

    function approve(address _spender, uint256 _value) virtual public returns (bool);

    function transfer(address _to, uint256 _value) virtual public returns (bool);
}

abstract contract IWant {
    function mint(address account) virtual external returns (uint);

    function totalSupply() public view virtual returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) virtual public returns (bool);

    function balanceOf(address _account) virtual view public returns (uint256);

    function transfer(address _to, uint256 _value) public virtual returns (bool);
}

    struct HeightProfit {
        int startHeight; //高度
        int height; //高度
        int ratio;  //分配数额
        int total;  //总质押量
    }

contract Staker is Ownable {
    address public LPTokenAddr;
    address public WantAddr;

    uint public startStakeHeight;
    uint public endStakeHeight;
    uint public startUnStakeHeight;
    uint public endUnStakeHeight;

    bool public pauseStake;
    bool public pauseUnStake;

    int public stakeTotal;

    mapping(address => int) public lastClaimHeightMap;
    mapping(address => int) public stakeNum;
    mapping(address => int) public balanceMap;
    mapping(uint => uint) public heightRatio;

    HeightProfit[] private heights;

    ILPToken private lpToken;
    IWant private want;

    event Stake(address _addr, int _num);
    event UnStake(address _addr, int _num);
    event Claim(address _addr, int _num);


    function pauseDep() onlyOwner public {
        pauseStake = true;
    }

    function unpauseDep() onlyOwner public {
        pauseStake = false;
    }

    function pauseUnDep() onlyOwner public {
        pauseUnStake = true;
    }

    function unpauseUnDep() onlyOwner public {
        pauseUnStake = false;
    }

    function setLPTokenAddr(address _addr) onlyOwner public {
        LPTokenAddr = _addr;
        lpToken = ILPToken(_addr);
    }

    function setWantAddr(address _addr) onlyOwner public {
        WantAddr = _addr;
        want = IWant(_addr);
    }

    function setPeriodConf(uint _startHeight, uint _endHeight, uint _startUnHeight, uint _endUnHeight) onlyOwner public {
        startStakeHeight = _startHeight;
        endStakeHeight = _endHeight;
        startUnStakeHeight = _startUnHeight;
        endUnStakeHeight = _endUnHeight;
    }

    function setHeightProfit(int _ratio) onlyOwner public {
        if (heights.length == 0) {
            heights.push(HeightProfit(0, int(block.number), _ratio, stakeTotal));
        } else {
            heights.push(HeightProfit(heights[heights.length - 1].height + 1, int(block.number), _ratio, stakeTotal));
        }
    }

    function getReward() public view returns (int _reward){
        int sum = getUnClaimReward(msg.sender);
        return sum;
    }

    function stake(int _num, address _to) public {
        require(int(lpToken.balanceOf(msg.sender)) >= _num, "Error: lp token balance not enough");
        require(block.number >= startStakeHeight && block.number <= endStakeHeight, "Error: Not stake time!");
        require(!pauseStake, "Error: Stake paused!");

        if (stakeNum[_to] != 0) {
            balanceMap[_to] += getUnClaimReward(_to);
        }
        if (int(heights.length) == 0) {
            lastClaimHeightMap[_to] = int(heights.length);
        } else {
            lastClaimHeightMap[_to] = int(heights.length) - 1;
        }


        lpToken.transferFrom(msg.sender, address(this), uint(_num));
        stakeNum[_to] += _num;
        stakeTotal += _num;

        emit Stake(_to, _num);
    }

    function unStake(int _num) public {
        require(stakeNum[msg.sender] >= _num, "Error:stake lpToken balance not enough");
        require(block.number >= startUnStakeHeight && block.number <= endUnStakeHeight, "Error: Not stake time!");
        require(!pauseUnStake, "Error:UnStake paused!");

        int sum = getUnClaimReward(msg.sender);
        if (int(heights.length) == 0) {
            lastClaimHeightMap[msg.sender] = int(heights.length);
        } else {
            lastClaimHeightMap[msg.sender] = int(heights.length) - 1;
        }

        balanceMap[msg.sender] += sum;

        lpToken.transfer(msg.sender, uint(_num));
        stakeNum[msg.sender] -= _num;
        stakeTotal -= _num;

        emit UnStake(msg.sender, _num);
    }


    function claim() public {
        int sum = getUnClaimReward(msg.sender);
        if (int(heights.length) == 0) {
            lastClaimHeightMap[msg.sender] = int(heights.length);
        } else {
            lastClaimHeightMap[msg.sender] = int(heights.length) - 1;
        }
        sum += balanceMap[msg.sender];

        require(sum > 0, "Error:balance not enough");

        //todo:发币方式
        want.transfer(msg.sender, uint(sum));

        balanceMap[msg.sender] = 0;

        emit Claim(msg.sender, sum);
    }

    function getAvailable() public view returns (int _available) {
        int sum = getUnClaimReward(msg.sender);
        sum += balanceMap[msg.sender];
        return sum;
    }

    function getLatestInterest() public view returns (int _interest) {
        if (heights.length == 0) {
            return 0;
        }
        return heights[heights.length - 1].ratio;
    }

    function getUnClaimReward(address _owner) internal view returns (int _reward){
        int index = lastClaimHeightMap[_owner];
        int sum;
        for (int i = index + 1; i < int(heights.length); i++) {
            sum += stakeNum[_owner] * heights[uint(i)].ratio;
        }
        return sum;
    }

    function getAllReward() public view returns (int _reward) {
        int sum;
        for (int i = 0; i < int(heights.length); i++) {
            sum += heights[uint(i)].total * heights[uint(i)].ratio;
        }
        return sum;
    }

    function withdrawLP(address _addr) public onlyOwner {
        lpToken.transfer(_addr, lpToken.balanceOf(address(this)));
    }

}