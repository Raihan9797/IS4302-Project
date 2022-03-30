pragma solidity ^0.5.0;

contract Habit {

    struct user {
        address addr;
        uint256 pledge_amt;
        bool is_loser;
        uint8[5] check_list;
    }

    // user addr -> User struct & attributes
    // Mapping users address -> user
    
    struct habit {
        mapping(address => user) users;
        mapping(uint256 => address) user_addresses;
        address owner;
        uint start_time;
        uint end_time;
        uint256 pool;
        uint256 num_users;
    }

    address con_owner = msg.sender;
    uint256 public num_habits = 0;
    uint256 public main_pool = 0;
    mapping(uint256 => habit) public habits;

    event CreateHabit(address owner, uint256 habit_id, uint start_time);
    event JoinHabit(address joiner, uint256 habit_id, uint256 pledge_amt);
    event EndHabit(address winner, uint256 habit_id, uint256 win_amt);

    modifier is_valid_id(uint256 habit_id) {
        require(habit_id < num_habits, "Invalid habit id");
        _;
    }

    /**
    * @dev Creates and starts the challenge
    * @param start_time_ expects Unix timestamp in seconds
    *
    * Requirements:
    *
    * - `start_time_` must be in the future
    */
    function create_habit(uint start_time_) public {
        require(block.timestamp < start_time_, "Start time must be in the future");
        habit memory new_habit = habit(
            {
                owner: msg.sender,
                start_time: start_time_,
                end_time: start_time_ + 5 days,
                pool: 0,
                num_users: 0
            }
        );

        uint256 new_habit_id = num_habits++;
        habits[new_habit_id] = new_habit;
        emit CreateHabit(msg.sender, new_habit_id, start_time_);
    }

    /**
    * @dev User joins the challenge with a pledge
    * @param habit_id expects a valid habit id
    * 
    * Requirements:
    * - `habit_id` is a valid id
    * - `msg.sender` is not part of challenge already
    */
    function join_habit(uint256 habit_id) public payable is_valid_id(habit_id) {
        require(msg.value > 0, "Pledge amount must be more than 0");
        require(habits[habit_id].users[msg.sender].addr == address(0), "User has already joined habit");
        user memory user_ = user(
            {
                addr: msg.sender,
                pledge_amt: msg.value,
                is_loser: false,
                check_list: [0, 0, 0, 0, 0] 
            }
        );
        habits[habit_id].pool += msg.value;
        habits[habit_id].users[msg.sender] = user_;
        // Added these two lines to keep track of all the addresses taking part in this habit
        habits[habit_id].user_addresses[habits[habit_id].num_users] = msg.sender;
        habits[habit_id].num_users++;
        emit JoinHabit(msg.sender, habit_id, msg.value);
    }

    /**
    * @dev Ends the challenge and distributes the reward
    * @param habit_id expects a valid habit id
    * 
    * Requirements:
    * - `habit_id` is a valid id
    * - `msg.sender` is owner of this contract
    */
    function end_habit(uint256 habit_id) public is_valid_id(habit_id) {
        require(msg.sender == con_owner, "Only owner of this contract can call this method");
        // require(block.timestamp > habits[habit_id].end_time, "Can only end this habit after end time");
        address[] memory winners = new address[](habits[habit_id].num_users);
        uint256 num_winners = 0;
        for (uint i = 0; i < habits[habit_id].num_users; i ++) {
            address working_user_add = habits[habit_id].user_addresses[i];
            user memory working_user = habits[habit_id].users[working_user_add];
            if (!working_user.is_loser) {
                winners[i] = working_user_add;
                num_winners++;
            }
        }
        uint256 to_distribute = habits[habit_id].pool / num_winners;
        for (uint j = 0; j < num_winners; j++) {
            address payable recipient = address(uint160(winners[j]));
            recipient.transfer(to_distribute);
            emit EndHabit(recipient, habit_id, to_distribute);
        }

        delete habits[habit_id];
    }
    /*
    // users call this to verify their habit each day
    // will also be used to check if user
    function verify() {
        require(msg.sender in users)
        require(start date <= current date <= end date)
        user  = users[msg.sender]
        require(user.is_loser is False) // no point verifying a loser
        
    If verification timestamp within acceptable time:
            Index = offset of current date from start date
            For day up till end of current day:
                If any day is False:
                    Set user.is_loser to True
                Elif day is current day:
                    Set check_list[idx] to True
        Else
            Set user.is_loser to True
    }

    // owner can end the contract after the start date
    // find out who won & distribute the funds from the loser’s pool
    Void end_contract():
        require(msg.sender is owner)
        Loser_pool = 0    
        For idx in users mapping:
            Addr, User = users[idx]
            If user.is_loser:
                Loser_pool += user.pledge

        If there are losers:
        Winner_pool = total_pool - loser_pool
    For idx in users mapping:
            Addr, user = users[idx]
            If not user.is_loser:
                Winnings = user.pledge + (user.pledge/winner_pool) * loser_pool
                addr.transfer(winnings) // transfer user's winnings
    Else: // just trf pledge amount back to all users
        For idx in users.mapping:
            Addr, user = users[idx]
            addr.transfer(user.pledge)

    selfdestruct(owner) // destroy the contract & send
    */

    function get_start_time(uint256 habit_id) public view is_valid_id(habit_id) returns (uint) {
        return habits[habit_id].start_time;
    }

    function get_end_time(uint256 habit_id) public view is_valid_id(habit_id) returns (uint) {
        return habits[habit_id].end_time;
    }

    function get_owner(uint256 habit_id) public view is_valid_id(habit_id) returns (address) {
        return habits[habit_id].owner;
    }

    function get_num_habits() public view returns (uint256) {
        return num_habits;
    }

    function get_pool(uint256 habit_id) public view is_valid_id(habit_id) returns (uint256) {
        return habits[habit_id].pool;
    }

    /// Checks if user joined a habit
    function is_user_joined_habit(uint256 habit_id, address user_) public view is_valid_id(habit_id) returns (bool) {
        return habits[habit_id].users[user_].addr != address(0);
    }

    // Returns owner of contract
    function get_con_owner() public view returns (address) {
        return con_owner;
    }

}

