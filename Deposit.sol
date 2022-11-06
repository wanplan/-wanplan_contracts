// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ILPToken {
    function approve(address spender, uint value) virtual external returns (bool);

    function transfer(address to, uint value) virtual external returns (bool);

    function transferFrom(address from, address to, uint value) virtual external returns (bool);

    function balanceOf(address owner) virtual external view returns (uint);
}

abstract contract IWant {
    function mint(address account) external virtual returns (uint);

    function totalSupply() external view virtual returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool);

    function balanceOf(address _account) public virtual view  returns (uint256);

    function transfer(address _to, uint256 _value) external virtual returns (bool);
}

    struct HeightProfit {
        uint startHeight; //高度
        uint height; //高度
        uint ratio;  //分配数额
        uint total;  //总质押量
    }

contract Staker is Ownable {

    address public lPTokenAddr;
    address public wantAddr;

    uint public startStakeHeight;
    uint public endStakeHeight;
    uint public startUnStakeHeight;
    uint public endUnStakeHeight;

    bool public pauseStake;
    bool public pauseUnStake;

    uint public stakeTotal;

    mapping(address => uint) public lastClaimHeightMap;
    mapping(address => uint) public stakeNum;
    mapping(address => uint) public balanceMap;
    mapping(uint => uint) public heightRatio;

    HeightProfit[] private heights;
    ILPToken private lpToken;
    IWant private want;

    event Stake(address _addr, uint _num);
    event UnStake(address _addr, uint _num);
    event Claim(address _addr, uint _num);


    function pauseDep() external onlyOwner {
        pauseStake = true;
    }

    function unpauseDep() external onlyOwner {
        pauseStake = false;
    }

    function pauseUnDep() external onlyOwner {
        pauseUnStake = true;
    }

    function unpauseUnDep() external onlyOwner {
        pauseUnStake = false;
    }

    function setLPTokenAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        lPTokenAddr = _addr;
        lpToken = ILPToken(_addr);
    }

    function setWantAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        wantAddr = _addr;
        want = IWant(_addr);
    }

    function setPeriodConf(uint _startHeight, uint _endHeight, uint _startUnHeight, uint _endUnHeight) external onlyOwner {
        startStakeHeight = _startHeight;
        endStakeHeight = _endHeight;
        startUnStakeHeight = _startUnHeight;
        endUnStakeHeight = _endUnHeight;
    }

    function setHeightProfit(uint _ratio) external onlyOwner {
        if (heights.length == 0) {
            heights.push(HeightProfit(0, block.number, _ratio, stakeTotal));
        } else {
            heights.push(HeightProfit(heights[heights.length - 1].height + 1, block.number, _ratio, stakeTotal));
        }
    }

    function stake(uint _num, address _to) external {
        require(_num > 0, "num must greater than zero");
        require(lpToken.balanceOf(msg.sender) >= _num, "Error: lp token balance not enough");
        require(block.number >= startStakeHeight && block.number <= endStakeHeight, "Error: Not stake time!");
        require(!pauseStake, "Error: Stake paused!");

        if (stakeNum[_to] != 0) {
            balanceMap[_to] += getUnClaimReward(_to);
        }
        if (heights.length == 0) {
            lastClaimHeightMap[_to] = heights.length;
        } else {
            lastClaimHeightMap[_to] = heights.length - 1;
        }


        lpToken.transferFrom(msg.sender, address(this), _num);
        stakeNum[_to] += _num;
        stakeTotal += _num;

        emit Stake(_to, _num);
    }

    function unStake(uint _num) external {
        require(_num > 0, "num must greater than zero");
        require(stakeNum[msg.sender] >= _num, "Error:stake lpToken balance not enough");
        require(block.number >= startUnStakeHeight && block.number <= endUnStakeHeight, "Error: Not stake time!");
        require(!pauseUnStake, "Error:UnStake paused!");

        uint sum = getUnClaimReward(msg.sender);
        if (heights.length == 0) {
            lastClaimHeightMap[msg.sender] = heights.length;
        } else {
            lastClaimHeightMap[msg.sender] = heights.length - 1;
        }

        balanceMap[msg.sender] += sum;

        lpToken.transfer(msg.sender, _num);
        stakeNum[msg.sender] -= _num;
        stakeTotal -= _num;

        emit UnStake(msg.sender, _num);
    }


    function claim() external {
        uint sum = getUnClaimReward(msg.sender);
        if (heights.length == 0) {
            lastClaimHeightMap[msg.sender] = heights.length;
        } else {
            lastClaimHeightMap[msg.sender] = heights.length - 1;
        }
        sum += balanceMap[msg.sender];

        require(sum > 0, "Error:balance not enough");

        //todo:发币方式
        want.transfer(msg.sender, sum);

        balanceMap[msg.sender] = 0;

        emit Claim(msg.sender, sum);
    }

    function getAvailable() external view returns (uint _available) {
        _available = getUnClaimReward(msg.sender);
        _available += balanceMap[msg.sender];
        return _available;
    }

    function getLatestInterest() external view returns (uint _interest) {
        if (heights.length == 0) {
            return 0;
        }
        return heights[heights.length - 1].ratio;
    }

    function getUnClaimReward(address _owner) internal view returns (uint _reward){
        uint index = lastClaimHeightMap[_owner];
        for (uint i = index + 1; i < heights.length; i++) {
            _reward += stakeNum[_owner] * heights[i].ratio;
        }
        return _reward;
    }

    function getAllReward() external view returns (uint _reward) {
        for (uint i = 0; i < heights.length; i++) {
            _reward += heights[i].total * heights[i].ratio;
        }
        return _reward;
    }

    function withdrawLP(address _addr) external onlyOwner {
        lpToken.transfer(_addr, lpToken.balanceOf(address(this)));
    }

}