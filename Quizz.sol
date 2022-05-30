// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract Quizz {

    address payable public owner;
    string result;
    uint public numOfQuestions;
    uint numOfTest;
    uint correctAnswer;

    struct Question {
        uint testId;
        uint number;
        string quest;
        string optA;
        string optB;
        string optC;
        string optKey;
    }

    struct Test {
        uint id;
        string name;
        uint minimumScore;
        uint reward;
    }

    struct Participant {
        string name;
        string email;
        string mobile_number;
    }

    constructor(){
        numOfQuestions = 0;
        correctAnswer = 0;
        owner = msg.sender;

        // create default test
        createTest(1, "Math", 60, 10);

        // create default question, you can add other question by use addQuestion function
        addQuestion(1, 1, "1 + 1 = ?", "1", "2", "3", "b");
        addQuestion(1, 2, "1 + 2 = ?", "1", "2", "3", "c");
    }

    mapping(uint => Question) quests;

    Test test;
    // only owner can acccess this function
    function createTest(uint _id, string memory _name, uint _minimumScore, uint _reward) public isOwner {
        numOfTest++;
        test = Test(_id, _name, _minimumScore, _reward);
    }

    // only owner can acccess this function
    // require to create test first before use this function
    function addQuestion(uint _testId, uint _number, string memory _quest,string memory _optA, string memory _optB, string memory _optC, string memory _optKey) public isOwner {
        require(numOfTest > 0, "Plase create Test first");
        numOfQuestions++;
        quests[numOfQuestions] = Question(_testId, _number, _quest, _optA, _optB, _optC, _optKey);
    }

    Participant participant;
    // only participant can acccess this function
    // rate is 2 ether
    function registration(string memory _name, string memory _email, string memory _mobile_number) payable external isParticipant checkQuizRates(2 ether) {
        participant = Participant(_name, _email, _mobile_number);
        owner.transfer(msg.value);
    }

    // show question of test by number of question    
    function showQuestion(uint _number) view public returns (uint, string memory, string memory, string memory, string memory) {
        Question memory q = quests[_number];
        return (
            q.number, 
            q.quest, 
            string(abi.encodePacked("a. ", q.optA)), 
            string(abi.encodePacked("b. ", q.optB)), 
            string(abi.encodePacked("c. ", q.optC))
        );
    }

    // only participant can acccess this function
    function startTest(uint _number, string memory _answer) public isParticipant {
        require(_number > 0 && _number <= numOfQuestions);
        if (keccak256(abi.encodePacked(_answer)) == keccak256(abi.encodePacked(quests[_number].optKey))) {
            correctAnswer++;
        }
    }

    // checking for correct answer
    function testChecking() payable external {
        uint score = 0;
        score = correctAnswer / numOfQuestions * 100;
        if(score >= test.minimumScore) {
            result = string(abi.encodePacked("Congratulation ", participant.name, ", You passed the test!"));
        } else {
            result = string(abi.encodePacked("Sorry ", participant.name, ", You can try again later"));
        }
    }

    // view result
    function viewResult() public view returns (string memory) {
        return result;
    }

    modifier isOwner {
        require (owner == msg.sender, "Only admin can access this function");
        _;
    }

    modifier isParticipant {
        require (owner != msg.sender, "Only participant can access this function");
        _;
    }

    modifier checkQuizRates(uint _rates) {
        require (msg.value >= _rates, "Insufficient payment, the rate is 2 ether");
        _;
    }
}