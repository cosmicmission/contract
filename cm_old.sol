/**
 *Submitted for verification at BscScan.com on 2022-02-22
*/

pragma solidity ^0.5.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

    

contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    
    address internal root = msg.sender;
    modifier onlyOwner() {
        require(msg.sender == root);
        _;
    }

    uint public contractBlock = block.number; 
    uint internal monBlock = 20*60*24*30;
    uint internal yearBlock = 20*60*24*30*12;
    uint public nextMechanismBlock = contractBlock.add(monBlock.mul(3));
    uint public nextMiningBlock = 0;
    uint public mechanismCount = 36;
    uint public miningCount = 5;
    uint256 public miningLock = 37500000*10**6;
    uint256 public mechanismLock = 7500000*10**6;
    uint256 public TotalLock = 45000000*10**6;
    uint256 internal mechanismAmount = 208333*10**6;
    uint256 internal miningAmount = 7500000*10**6;
    
    address internal pool = address(0x063c2069330945a20b05fEaaa3D39120A4b04bC8);
    address internal mining = address(0xF27790c6d2E8FE3AD064620a4974CAA1c4755Ef0);
    address internal whiteList = address(0xDe6453b9b49CE3A0Abe91261753c30f46130C68C);
    address internal dao = address(0xC20ab3F2E20C8F6405366995aE877C53a829fCb8);
    address internal mechanism = address(0x25e6478d9B1F7ABf1D56F11025CF4CB78be1dA4A);

    function unlockMechanism() internal{
        require(mechanismLock > 0 , "ERC20: mining pool empty");
        uint256 amount = mechanismAmount;

        if(mechanismLock<amount) amount = mechanismAmount;
        _balances[root] = _balances[root].sub(amount);
        mechanismCount -=1;
        nextMechanismBlock = block.number.add(monBlock);
        mechanismLock = mechanismLock.sub(amount);
        TotalLock = TotalLock.sub(amount);
        _balances[mechanism] = _balances[mechanism].add(amount);
        emit Transfer(root, mechanism, amount);
    }
    function unlockMining () internal {
        require(miningCount > 0 , "ERC20: not count");
        require(miningLock > 0 , "ERC20: mining pool empty");

        uint256 amount = miningAmount;
        if(miningLock<amount) amount = miningLock;
        
        _balances[root] = _balances[root].sub(amount);
        miningCount -= 1;
        nextMiningBlock = block.number.add(yearBlock);
        miningLock = miningLock.sub(amount);
        TotalLock = TotalLock.sub(amount);
        _balances[mining] = _balances[mining].add(amount);
        emit Transfer(root, mining, amount);
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if(block.number>=nextMiningBlock && miningCount>0) unlockMining();
        if(block.number>=nextMechanismBlock && mechanismCount>0) unlockMechanism();

        if(sender!=root){
            if (_totalSupply > 20000000*10**6 ){
                uint256 delta = _totalSupply.sub(20000000*10**6);
                uint256 burn_amount = amount.mul(5).div(100);
                uint256 _pool = amount.mul(2).div(100);
                uint256 _pool2 = burn_amount.sub(_pool);

                if (delta > burn_amount){
                    _totalSupply = _totalSupply.sub(_pool2);
                    _balances[pool] = _balances[pool].add(_pool);
                    emit Transfer(sender, pool, _pool);
                }else{
                    _totalSupply = 20000000*10**6;
                    amount = amount.sub(delta);
                }
                
            }
        }else{
            uint256 activeNum = _balances[sender].sub(TotalLock);
            if(amount>activeNum) amount = activeNum;
        }

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);

        _balances[account] = _balances[account].add(amount);
        _transfer(account,whiteList,2500000*10**6);
        _transfer(account,dao,2500000*10**6);
        emit Transfer(address(0), account, amount);
    }
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract Token is ERC20, ERC20Detailed {
    constructor () public ERC20Detailed("COSMIC MISSION", "CM", 6) {
        _mint(msg.sender, 50000000 * (10 ** uint256(decimals())));
    }
}
