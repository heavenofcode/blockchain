// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.9;

contract Quizz {

    // each question has four answer choices and only one correct anser choice
    struct Question {
        string question;
        string correctAns;
        string wrongAns1;
        string wrongAns2;
        string wrongAns3;
    }

    struct QuizzEvent {
        uint id;
        address creator;
        string name;
        uint fee;
        uint pool;
        Question q1;
        mapping(address => bool) hasPaid;
        mapping(address => bool) attempts;
    }

    // stores the same information as a quiz except for question information
    struct QuizzDisplayable {
        uint id;
        string name;
        uint fee;
        uint pool;
        mapping(address => bool) attempts;
    }

    mapping(uint => QuizzEvent) quizzes;
    mapping(uint => QuizzDisplayable) quizzDisp;

    uint public numOfQuizzes;

    event fetchquizz (uint indexed _quizzId); // get quizz questions
    event quizztaken (uint indexed _quizzId); // quizz answers submitted

    // upon contract creation, initialize number of quizzes to 0 and create a new quizz event
    constructor () public {
        numOfQuizzes = 0;
        // makeQuizz("Sample Quizz", 1, 0, "2 + 2 =", "4", "3", "5", "2");
    }

    // increment number of quizzes
    // create a new quizz event and add it to the list of quizzes
    // create a new quizz displayable and add it to the list of displayable quizzes
    // add the creator as a user who has attempted so the creator cannot attempt the quizz
    function makeQuizz (string memory _name, uint _fee, uint _pool, string memory _question, string memory _ans1, string memory _ans2, string memory _ans3, string memory _ans4) public {
        numOfQuizzes ++;
        quizzes[numOfQuizzes] = QuizzEvent(numOfQuizzes, msg.sender, _name, _fee, _pool, Question(_question, _ans1, _ans2, _ans3, _ans4));
        quizzDisp[numOfQuizzes] = QuizzDisplayable(numOfQuizzes, _name, _fee, _pool);
        quizzes[numOfQuizzes].attempts[msg.sender] = true;
    }

    // returns quizz information for _quizzId without returning the questions
    function getQuizzDisp(uint _quizzId) view public returns(uint, string memory, uint, uint) {
        QuizzDisplayable memory temp = quizzDisp[_quizzId];
        return (temp.id, temp.name, temp.fee, temp.pool);
    }

    // adds the user to the list of users who have attemped this quizz
    function setAttempt(uint _quizzId) public {
        quizzes[_quizzId].attempts[msg.sender] = true;
    }

    // checks to see if the user has paid but has not attempted
    // this is used to bypass the front-end form to submit the fee
    function canSkip(uint _quizzId) view public returns (bool) {
        bool skip = quizzes[_quizzId].hasPaid[msg.sender] && !quizzes[_quizzId].attempts[msg.sender];
        return skip;
    }

    // requires that the quizz event exists\
    // requires that the account trying to access the quizz information has not taken it before
    // once the account receives the quizz, add the account to the list of accounts that have attempted this quizz
    function getQuizz(uint _quizzId) view public returns (string memory, string memory, string memory, string memory, string memory) {
        require(_quizzId > 0 && _quizzId <= numOfQuizzes);
        require(!quizzes[_quizzId].attempts[msg.sender]);
        Question memory q = quizzes[_quizzId].q1;
        return (q.question, q.correctAns, q.wrongAns1, q.wrongAns2, q.wrongAns3);
    }

    // requires that the quizz exists
    // requires that the account has not attempted the quizz before
    // allows users to send money
    // the contract's account balance will hold all of the ether for all quizz event pools
    // require that amount paid is greater than equal to current amount in pool
    // add fee to the pool of _quizzId
    // add the user to the mapping has paid to indicate that the user has paid the appropriate fee to take the quizz
    // fetch the quizz for the user to access.
    function payToPlay(uint _quizzId) public payable {
        require(_quizzId > 0 && _quizzId <= numOfQuizzes); // checks if quizz exist
        require(!quizzes[_quizzId].attempts[msg.sender]); // checks if they have not attempted
        require(msg.value >= quizzes[_quizzId].fee); // if they paid the right amount
        quizzes[_quizzId].pool += msg.value;
        quizzes[_quizzId].hasPaid[msg.sender] = true;
        emit fetchquizz(_quizzId);
    }

    // returns the number of quiz events
    function getNum() public view returns (uint) {
        return numOfQuizzes;
    }
    
    // requires that the quiz exists
    // returns the current pool amount of the quizz event _quizzId
    // show the user how much reward a certain quizz has
    function getPoolAmount(uint _quizzId) view public returns (uint) {
        require(_quizzId > 0 && _quizzId <= numOfQuizzes); // checking if quizz exists
        return quizzes[_quizzId].pool;
    }

    // requires that the quizz event exists
    // requires that the account has paid the fee to attempt the quizz
    // requires that the account has attempted the quizz
    // hashes the question's correct answer and the answer submitted by the account and compares the two hashes
    // if the two hashes are equal, then return true, otherwise false
    function scoreAttempt(uint _quizzId, string memory _ans) view public returns (bool) {
        require(_quizzId > 0 && _quizzId <= numOfQuizzes);
        require(quizzes[_quizzId].hasPaid[msg.sender]);
        require(quizzes[_quizzId].attempts[msg.sender]);
        return (keccak256(abi.encodePacked(_ans)) == keccak256(abi.encodePacked(quizzes[_quizzId].q1.correctAns)));
    }
    
    // requires that the account has paid the fee to attempt the quizz
    // requires that the account has attempted the quizz
    // transfer the amount of ether in the pool of _quizzId to the winner
    // set the _quizzId pool amount to 0
    function awardLottery (uint _quizzId, address payable _winner) public {
        require(quizzes[_quizzId].hasPaid[_winner]);
        require(quizzes[_quizzId].attempts[_winner]);
        _winner.transfer(quizzes[_quizzId].pool);
        quizzes[_quizzId].pool = 0;
    }
}