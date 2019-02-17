pragma solidity ^0.5.0;
//import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
//import 'openzeppelin-solidity/contracts/math/SafeMath.sol';

contract PoolTogether {

  address public owner;
  uint public creationTime;
  address[] public entrants;
  //address[] private entrants;

  // Balances allowed to withdraw from contract
  mapping (address => uint) savings;
  mapping (address => uint) entryMap;

  uint pool = 0;
  uint min = 10 finney;

  constructor () public {
    //address compoundFinanceMM = "0x3fda67f7583380e67ef93072294a7fac882fd7e7"
    //address public rinkDai = "0x4e17c87c52d0e9a0cad3fbc53b77d9514f003807";
    owner = msg.sender;
    creationTime = now;
  }



  //States of Contract:
  //PoolOpen: Accepting
  //Saving: and Earning
  //PayOut: Withdraw
  enum States {
    PoolOpen,  //0
    Saving,    //1
    PayOut     //2
  }

  States state = States.PoolOpen;

  modifier atState(States _state) {
    require(
      state == _state,
      "Function cannot be called at this time."
    );
    _;
  }

  //Time Variables (cumulative)
  uint freeSwim = 2 minutes;
  uint treadWater = freeSwim + 5 minutes;
  uint outOfPool = outOfPool + 3 minutes;

  // Perform timed transitions. Be sure to mention
  // this modifier first, otherwise the guards
  // will not take the new stage into account.
  modifier timedTransitions() {
    if (state == States.PoolOpen &&
      now >= creationTime + freeSwim)
      earnInterest();
    if (state == States.Saving &&
      now >= creationTime + treadWater)
      pickWinner();
    if (state == States.PayOut &&
      now >= creationTime + outOfPool)
      restartPool();
      // The other stages transition by transaction
        _;
  }


  // Event emitted when a saver dives into the pool
  event splashDown(address indexed saver, uint deposit, uint total);

  // Event emitted when a saver withdraws
  event takeHome(address indexed saver, uint savings);

  event Saving(States state);

    //When a saver joins the pool
    //Saver can add to deposit during PoolOpen
    function splash() public payable timedTransitions atState(States.PoolOpen) {
        //For use w/ DAI Tokens: require(transferFrom(msg.sender, address(this), deposit), "DRAW_FAILED");
        require(msg.value >= min);
        addEntrant(msg.sender);
        pool = pool + msg.value;
        savings[msg.sender] = savings[msg.sender] + msg.value;
        emit splashDown(msg.sender, msg.value, savings[msg.sender]);
    }

    //Add enntrant to pool of potential winners
    function addEntrant (address entrant) private {
        if(savings[entrant] == 0){
          //Only add to potential winners if current balance 0
          entrants.push(entrant);
          entryMap[entrant] = entrants.length - 1;
        }
        //Else: Already an active key
    }

    function checkDups() internal {
      // Check for duplicate addresses in entrants?
    }

    function nextStage() internal {
        state = States(uint(state) + 1);
    }

    function earnInterest() internal {
      //Earn Interest
      nextStage();
      emit Saving(state);
    }

    function pickWinner() internal {
      //Pick the Winner
      nextStage();
    }

    function restartPool() internal {
      creationTime = now;
      state = States(uint(0));
    }

    //Withdraw, only during PayOut period
    //Question: Do we pull the funds from earning source each iteration?
    // Or do we only pull funds that are requested (maximizing roll-over)?
    function withdraw() public timedTransitions atState(States.PayOut) {
          uint amount = savings[msg.sender];
          pool = pool - amount;
          // !re-entrancy : Zero the pending refund before
          savings[msg.sender] = 0;
          msg.sender.transfer(amount);
          removeSaver();
          emit takeHome(msg.sender, amount);
      }

  function removeSaver() private {
      //Copy last entry to slot occupied by withdrawing address
      entrants[entryMap[msg.sender]] = entrants[entrants.length - 1];
      //reset the entryMap  This is kind of risky with a 0 entrant index.
      entryMap[msg.sender] = 0;
      //delete the last entry element
      if(entrants.length > 1){
        entrants.pop();
      } else {
        //last entrant, set to owner
        entrants[0] = owner;
        //give balance to owner
      }
  }

  //View Status of contract State
  function stateOfPool() public view returns(States){
      return state;
  }

  //View Status of pool
  function poolSize() public view returns (uint){
      return pool;
  }

  //View Status of pool potential return in 100x percentage value
  //So 300 = 3.00%
  //Hardcoded now
  function poolReturn() public view returns(uint){
      return(300);
  }

  //View Status of saver deposit
  function myDeposit() public view returns(uint){
      return(savings[msg.sender]);
  }

  //View Entry Status
  function entryData() public view returns(uint Entries, uint Size){
    return(entrants.length,pool);
  }

  // Only for testing
  function setState(uint _stateVar) public {
      require(msg.sender == owner);
      state = States(_stateVar);
  }

}
