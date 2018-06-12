pragma solidity ^0.4.23;
import "../libs/SafeMath.sol";
import "../libs/FundTemplate.sol";
import "../permission/PermissionProviderInterface.sol";


contract TokenizationProvider {

    using SafeMath for uint256;

    //Permission Control
    PermissionProviderInterface internal permissionProvider;


    //modifier
    modifier onlyCore() {
        require(permissionProvider.has(msg.sender, permissionProvider.ROLE_CORE()));
        _;
    }

    modifier onlyWhitelist() {
        require(permissionProvider.has(msg.sender, permissionProvider.ROLE_FUND()));
        //require(permissionProvider.has(msg.sender, permissionProvider.ROLE_FUND()));
        _;
    }
    //event
    event TransferOwnership(uint _fundIndex, address _newOwner);

    //status
    uint fundLength;

    struct _fundDetail{
        uint fundId;
        string fundName;
        uint createTime;
    }

    //mapping

    mapping (uint => address) public fundIndex;
    mapping (uint => address) public fundOwner;
    mapping (address => _fundDetail) public fundDetail;

    //function

    function TokenizationIndex(address _permissionProvider) public {
        permissionProvider = PermissionProviderInterface(_permissionProvider);
    }


    //Create
    function createFund(
        string _name,
        string _symbol,
        uint _decimals,
        string _description,
        string _category,
        uint _withdrawFeeCycle,
        uint _lockTime,
        uint _withdrawFundCycle

    ) public
    ///////WARNING
    //onlyWhitelist
    returns (address FundAddress)
    {
       FundAddress = new FundTemplate(_symbol,_name,_decimals);

        //FundTemplate
        FundTemplate  _newFund;
        _newFund = FundTemplate(FundAddress);


        require(_newFund.createFundDetails(
          fundLength,
          _name,
          _description,
          _category,
          _withdrawFeeCycle,
          _withdrawFundCycle)
        );
        require(_newFund.setCore(msg.sender));
        require(_newFund.lockFund(_lockTime));
        fundOwner[fundLength] = tx.origin;
        fundIndex[fundLength] = FundAddress;
        //
        fundDetail[tx.origin].fundId = fundLength;
        fundDetail[tx.origin].fundName = _name;
        fundDetail[tx.origin].createTime = now;
        //
        fundLength += 1;
        return FundAddress;
    }

    //Get
    function getFundDetails(uint _fundId) public view returns(
        address _owner,
        string _name,
        string _symbol,
        uint _totalSupply,
        string _description,
        string _category,
        address[]  _tokenAddresses,
        uint[]  _amounts
    ){

        FundTemplate  _newFund;
        _owner = fundOwner[_fundId];
        _newFund = FundTemplate(fundIndex[_fundId]);
        ( ,
            _name,
            _symbol,
            _totalSupply,
            _description,
            _category,
            _tokenAddresses,
            _amounts
        )  = _newFund.getFundDetails();
    }


    function getFundOwner(uint _fundId) public view returns(address _fundOwner) {
        return fundOwner[_fundId];
    }

    function getFundAddress(uint _fundId) public view returns(address _fundAddress) {
        return fundIndex[_fundId];
    }


    function _checkLength(address[] _tokenAddresses,uint[] _weights) internal returns(bool success){
        require(_tokenAddresses.length == _weights.length);
        uint total = 0;
        for (uint i = 0; i < _weights.length; ++i) {
            total += _weights[i];
        }
        return (total <= 100 && total > 0);
    }
}
