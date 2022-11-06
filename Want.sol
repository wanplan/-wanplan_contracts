// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract IGM {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function tokenOfOwner(address _owner) public view virtual returns (uint[] memory);
}

interface IWanTSale {
    function getCountByGmId(uint256 _gmId) external view returns (uint256 _count);
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function createPair(address tokenA, address tokenB) external returns (address pair);

}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
}


contract WantImplementation {

    // ERC20 BASIC DATA
    mapping(address => uint256) internal balances;
    uint256 internal totalSupply_;
    string public constant name = "WanT"; // solium-disable-line
    string public constant symbol = "WanT"; // solium-disable-line uppercase
    uint8 public constant decimals = 18; // solium-disable-line uppercase

    // ERC20 DATA
    mapping(address => mapping(address => uint256)) internal allowed;

    // OWNER DATA
    address public owner;
    address public proposedOwner;

    // PAUSABILITY DATA
    bool public paused = false;

    // ASSET PROTECTION DATA
    mapping(address => bool) internal frozen;
    mapping(address => bool) internal whiteList;


    //Transfer tax
    uint256 public tax;
    uint256 public whiteTax;

    uint256 public valueInstituteTax = 5000;
    uint256 public lpTax = 3000;
    uint256 public burnTax = 2000;


    //assign coin
    address public stakeContractAddr;
    address public valueInstituteAddr;
    address public techCommunityAddr;

    mapping(address => bool) public transferWhiteList;
    mapping(uint256 => uint256) public countOfGmIdBuyWant;

    uint256 private DayWantSwapTotalCount = 1000 * 1 ether;
    uint256 private GmOfWantSwapTotalCount = 10000 * 1 ether;
    uint256 private GmOfWantSwapDayCount = 300 * 1 ether;
    uint256 private WantSwapEachMaxCount = 100 * 1 ether;
    uint256 private OwnerWantMaxCount = 300 * 1 ether;
    uint256 private NeedPrivateBuyWantCount = 500 * 1 ether;
    uint256 public DayMaxSupply;
    uint256 public DaySupply;


    //other address
    address public uniswapV2RouterAddr;
    address public uniswapV2PairAddr;
    address public gMAddr;
    address public tradeCoinAddr;
    address public wanTSaleAddr;

    IGM private gm;
    IWanTSale private wanTSale;

    uint256 public dayNum;
    mapping(uint256 => uint256) public gmIdDayBuyCount;
    mapping(uint256 => uint256) public gmIdDayNum;


    uint256 public constructTime;
    uint256 public linearReleaseCount;
    uint256 public linearReleaseRemain;

    bool public publicSale;

    /**
     * EVENTS
     */

    // ERC20 BASIC EVENTS
    event Transfer(address indexed from, address indexed to, uint256 value);

    // ERC20 EVENTS
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // OWNABLE EVENTS
    event OwnershipTransferProposed(
        address indexed currentOwner,
        address indexed proposedOwner
    );
    event OwnershipTransferDisregarded(
        address indexed oldProposedOwner
    );
    event OwnershipTransferred(
        address indexed oldOwner,
        address indexed newOwner
    );

    /**
     * The constructor is used here to ensure that the implementation
     * contract is initialized. An uncontrolled implementation
     * contract might lead to misleading state
     * for users who accidentally interact with it.
     */
    constructor() {
        owner = msg.sender;
        totalSupply_ = 210 * 10 ** 4 * 10 ** 18;
        balances[msg.sender] = 205 * 10 ** 4 * 10 ** 18;
        linearReleaseRemain = 5 * 10 ** 4 * 10 ** 18;
        constructTime = block.timestamp;
        pause();
    }

    function setWanTSaleAddr(address _addrGM, address _addrWant, address _addrTradeC) external onlyOwner {
        require(_addrGM != address(0) && _addrWant != address(0) && _addrTradeC != address(0), "address can not be zero!");
        gMAddr = _addrGM;
        gm = IGM(_addrGM);

        wanTSaleAddr = _addrWant;
        wanTSale = IWanTSale(_addrWant);

        tradeCoinAddr = _addrTradeC;
    }

    function setOtherAddress(address _addrValue, address _addrTech, address _addrStake) external onlyOwner {
        require(_addrValue != address(0) && _addrTech != address(0) && _addrStake != address(0), "address can not be zero!");
        valueInstituteAddr = _addrValue;
        techCommunityAddr = _addrTech;
        stakeContractAddr = _addrStake;
    }

    function setCountConf(uint256 _dayWantSwapTotalCount, uint256 _gmOfWantSwapTotalCount, uint256 _gmOfWantSwapDayCount,
        uint256 _wantSwapEachMaxCount, uint256 _ownerWantMaxCount, uint256 _needPrivateBuyWantCount) external onlyOwner {
        DayWantSwapTotalCount = _dayWantSwapTotalCount;
        GmOfWantSwapTotalCount = _gmOfWantSwapTotalCount;
        GmOfWantSwapDayCount = _gmOfWantSwapDayCount;
        WantSwapEachMaxCount = _wantSwapEachMaxCount;
        OwnerWantMaxCount = _ownerWantMaxCount;
        NeedPrivateBuyWantCount = _needPrivateBuyWantCount;
    }

    function setDayMaxSupply(uint256 _count) external onlyOwner {
        DayMaxSupply = _count;
        DaySupply = 0;
    }

    function getCountConf() external view returns (uint256 _dayWantSwapTotalCount, uint256 _gmOfWantSwapTotalCount, uint256 _gmOfWantSwapDayCount,
        uint256 _wantSwapEachMaxCount, uint256 _ownerWantMaxCount, uint256 _needPrivateBuyWantCount) {
        return (DayWantSwapTotalCount, GmOfWantSwapTotalCount, GmOfWantSwapDayCount, WantSwapEachMaxCount, OwnerWantMaxCount, NeedPrivateBuyWantCount);
    }

    function setTax(uint256 _tax, uint256 _whiteTax) external onlyOwner {
        tax = _tax;
        whiteTax = _whiteTax;
    }

    function setTaxConf(uint256 _valueInstituteTax, uint256 _lpTax, uint256 _burnTax) external onlyOwner {
        valueInstituteTax = _valueInstituteTax;
        lpTax = _lpTax;
        burnTax = _burnTax;
    }

    function setUniswapV2RouterAddr(address _addr) external onlyOwner {
        require(_addr != address(0), "address can not be zero!");
        uniswapV2RouterAddr = _addr;
        IUniswapV2Router01 _uniswapV2Router = IUniswapV2Router01(_addr);
        IUniswapV2Factory _uniswapFactory = IUniswapV2Factory(_uniswapV2Router.factory());

        address _pairAddr = _uniswapFactory.getPair(address(this), tradeCoinAddr);
        if (_pairAddr == address(0)) {
            _pairAddr = _uniswapFactory.createPair(address(this), tradeCoinAddr);
        }
        uniswapV2PairAddr = _pairAddr;
    }

    function setDayNum(uint256 _dayNum) external onlyOwner {
        dayNum = _dayNum;
    }

    function openPublicSwap() external onlyOwner {
        publicSale = true;
    }

    function closePublicSwap() external onlyOwner {
        publicSale = false;
    }

    // ERC20 BASIC FUNCTIONALITY
    /**
    * @dev Returns the address of the current owner.
    */
    function getOwner() external view returns (address) {
        return owner;
    }

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() external view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Transfer token to a specified address from msg.sender
    * Note: the use of Safemath ensures that _value is nonnegative.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) external whenNotPaused returns (bool) {
        require(_to != address(0), "cannot transfer to address zero");
        require(!frozen[_to] && !frozen[msg.sender], "address frozen");

        //        uint256 _tax = _getTax(msg.sender, _value);
        require(_value <= balances[msg.sender], "insufficient funds");

        //买币 解除lp
        if (!publicSale) {
            require(_to == stakeContractAddr || msg.sender == stakeContractAddr || transferWhiteList[_to] || transferWhiteList[msg.sender], "operate illegality");
            if (!transferWhiteList[_to]) {
                require(DaySupply + _value <= DayMaxSupply, "over max day supply");
                uint[] memory gmIds = gm.tokenOfOwner(_to);
                (uint _remain,,uint _remainTotal,,uint _usableGmCount) = _getBuyCount(_to);
                require(OwnerWantMaxCount * _usableGmCount >= balanceOf(_to) + _value, "already over count of owner want");
                require(_remain >= _value, "over max day count");
                require(_remainTotal >= _value, "over max total count");
                require(WantSwapEachMaxCount >= _value, "over each swap count");
                uint256 _tmp = _value;
                for (uint i = 0; i < gmIds.length; i++) {
                    if (_tmp == 0) {
                        break;
                    }
                    if (wanTSale.getCountByGmId(gmIds[i]) < NeedPrivateBuyWantCount) {
                        continue;
                    }
                    uint256 def = GmOfWantSwapDayCount - gmIdDayBuyCount[gmIds[i]];
                    if (def <= 0) {
                        continue;
                    } else if (_tmp > def) {
                        _tmp -= def;
                        countOfGmIdBuyWant[gmIds[i]] += def;
                        gmIdDayBuyCount[gmIds[i]] += def;
                    } else {
                        countOfGmIdBuyWant[gmIds[i]] += _tmp;
                        gmIdDayBuyCount[gmIds[i]] += _tmp;
                        _tmp = 0;
                    }
                }
                DaySupply += _value;
            }
        }

        balances[msg.sender] = balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function _getTax(address _addr, uint256 _value) internal view returns (uint256) {
        if (whiteList[_addr]) {
            return _value * whiteTax / (1 ether);
        }
        return _value * tax / (1 ether);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param _addr The address to query the the balance of.
    * @return An uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address _addr) public view returns (uint256) {
        return balances[_addr];
    }

    // ERC20 FUNCTIONALITY

    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    external
    whenNotPaused
    returns (bool)
    {
        require(_from != address(0), "from can not address zero");
        require(!frozen[_to] && !frozen[_from] && !frozen[msg.sender], "address frozen");
        require(_value <= allowed[_from][msg.sender], "insufficient allowance");

        uint256 _tax = _getTax(_from, _value);
        require(_value <= balances[_from], "insufficient funds");

        if (!publicSale) {
            require(_to == stakeContractAddr || msg.sender == stakeContractAddr || transferWhiteList[_to] || transferWhiteList[_from], "operate illegality");
        }

        //卖币，加lp
        if (_tax != 0) {
            balances[stakeContractAddr] += (_tax * lpTax / 10000);
            balances[valueInstituteAddr] += (_tax * valueInstituteTax / 10000);
            balances[address(0)] += (_tax * burnTax / 10000);
            emit Transfer(_from, stakeContractAddr, (_tax * lpTax / 10000));
            emit Transfer(_from, valueInstituteAddr, (_tax * valueInstituteTax / 10000));
            emit Transfer(_from, address(0), (_tax * burnTax / 10000));
        }

        balances[_from] = balances[_from] - _value;
        balances[_to] = balances[_to] + _value - _tax;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;
        emit Transfer(_from, _to, _value - _tax);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) external whenNotPaused returns (bool) {
        require(!frozen[_spender] && !frozen[msg.sender], "address frozen");
        require(_spender != address(0), "address can not be zero");
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(
        address _owner,
        address _spender
    )
    external
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

    // OWNER FUNCTIONALITY

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "onlyOwner");
        _;
    }

    /**
     * @dev Allows the current owner to begin transferring control of the contract to a proposedOwner
     * @param _proposedOwner The address to transfer ownership to.
     */
    function proposeOwner(address _proposedOwner) external onlyOwner {
        require(_proposedOwner != address(0), "cannot transfer ownership to address zero");
        require(msg.sender != _proposedOwner, "caller already is owner");
        proposedOwner = _proposedOwner;
        emit OwnershipTransferProposed(owner, proposedOwner);
    }

    /**
     * @dev Allows the current owner or proposed owner to cancel transferring control of the contract to a proposedOwner
     */
    function disregardProposeOwner() external {
        require(msg.sender == proposedOwner || msg.sender == owner, "only proposedOwner or owner");
        require(proposedOwner != address(0), "can only disregard a proposed owner that was previously set");
        address _oldProposedOwner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferDisregarded(_oldProposedOwner);
    }

    /**
     * @dev Allows the proposed owner to complete transferring control of the contract to the proposedOwner.
     */
    function claimOwnership() external {
        require(msg.sender == proposedOwner, "onlyProposedOwner");
        address _oldOwner = owner;
        owner = proposedOwner;
        proposedOwner = address(0);
        emit OwnershipTransferred(_oldOwner, owner);
    }


    // PAUSABILITY FUNCTIONALITY

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused, "whenNotPaused");
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() public onlyOwner {
        paused = true;
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external onlyOwner {
        paused = false;
    }

    /**
     * @dev Freezes an address balance from being transferred.
     * @param _addr The new address to freeze.
     */
    function freeze(address _addr) external onlyOwner {
        frozen[_addr] = true;
    }

    /**
     * @dev Unfreezes an address balance allowing transfer.
     * @param _addr The new address to unfreeze.
     */
    function unfreeze(address _addr) external onlyOwner {
        frozen[_addr] = false;
    }

    /**
    * @dev Gets whether the address is currently frozen.
    * @param _addr The address to check if frozen.
    * @return A bool representing whether the given address is frozen.
    */
    function isFrozen(address _addr) external view returns (bool) {
        return frozen[_addr];
    }

    function addWhite(address _addr) external onlyOwner {
        whiteList[_addr] = true;
    }

    function removeWhite(address _addr) external onlyOwner {
        whiteList[_addr] = false;
    }

    function isWhite(address _addr) external view returns (bool) {
        return whiteList[_addr];
    }

    function addTransWhite(address _addr) external onlyOwner {
        transferWhiteList[_addr] = true;
    }

    function removeTransWhite(address _addr) external onlyOwner {
        transferWhiteList[_addr] = false;
    }

    function isTransWhite(address _addr) external view returns (bool) {
        return transferWhiteList[_addr];
    }

    function getBuyCount() external view returns (uint256 _remain, uint _dayTotal, uint _remainTotal, uint _total, uint _usableGmCount){
        uint[] memory gmIds = gm.tokenOfOwner(msg.sender);
        for (uint i = 0; i < gmIds.length; i++) {
            if (wanTSale.getCountByGmId(gmIds[i]) < NeedPrivateBuyWantCount) {
                continue;
            }
            _usableGmCount++;
            uint _day = gmIdDayNum[gmIds[i]];
            uint def = 0;
            if (_day < dayNum) {
                def = GmOfWantSwapDayCount;
            } else {
                def = GmOfWantSwapDayCount - gmIdDayBuyCount[gmIds[i]];
            }
            _total += GmOfWantSwapTotalCount;
            _dayTotal += GmOfWantSwapDayCount;

            uint256 totalDef = GmOfWantSwapTotalCount - countOfGmIdBuyWant[gmIds[i]];
            if (def > 0) {
                _remain += def;
            }
            if (totalDef > 0) {
                _remainTotal += totalDef;
            }
        }
        return (_remain, _dayTotal, _remainTotal, _total, _usableGmCount);
    }

    function _getBuyCount(address _addr) internal returns (uint256 _remain, uint _dayTotal, uint _remainTotal, uint _total, uint _usableGmCount) {
        uint[] memory gmIds = gm.tokenOfOwner(_addr);
        for (uint i = 0; i < gmIds.length; i++) {
            if (wanTSale.getCountByGmId(gmIds[i]) < NeedPrivateBuyWantCount) {
                continue;
            }
            _usableGmCount++;
            uint _day = gmIdDayNum[gmIds[i]];
            if (_day < dayNum) {
                gmIdDayNum[gmIds[i]] = dayNum;
                gmIdDayBuyCount[gmIds[i]] = 0;
            }
            _total += GmOfWantSwapTotalCount;
            _dayTotal += GmOfWantSwapDayCount;

            uint256 def = GmOfWantSwapDayCount - gmIdDayBuyCount[gmIds[i]];
            uint256 totalDef = GmOfWantSwapTotalCount - countOfGmIdBuyWant[gmIds[i]];
            if (def > 0) {
                _remain += def;
            }
            if (totalDef > 0) {
                _remainTotal += totalDef;
            }
        }
        return (_remain, _dayTotal, _remainTotal, _total, _usableGmCount);
    }

    function linearRelease() external {
        require(constructTime + (linearReleaseCount + 1) * 864000 <= block.timestamp, "not release time");
        uint256 _linearReleaseCount = linearReleaseCount;
        uint256 _linearReleaseRemain = linearReleaseRemain;

        for (; _linearReleaseRemain > 0; _linearReleaseCount++) {
            if (constructTime + (_linearReleaseCount + 1) * 864000 >= block.timestamp) {
                return;
            }
            if (_linearReleaseRemain / (4000 * 1 ether) > 0) {
                balances[techCommunityAddr] += (4000 * 1 ether);
                _linearReleaseRemain -= (4000 * 1 ether);
            } else {
                balances[techCommunityAddr] += _linearReleaseRemain;
                _linearReleaseRemain = 0;
            }
        }
        linearReleaseCount = _linearReleaseCount;
        linearReleaseRemain = _linearReleaseRemain;
    }

    function isReleaseTime() external view returns (bool){
        return constructTime + (linearReleaseCount + 1) * 864000 <= block.timestamp;
    }
}
