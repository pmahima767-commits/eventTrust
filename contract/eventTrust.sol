// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title eventTrust - Decentralized Event Management & Ticketing System
/// @notice Allows event organizers to create events, sell tickets, and manage attendance
contract Project {
    struct Event {
        uint256 id;
        string name;
        string location;
        uint256 date;
        uint256 price;
        uint256 ticketsAvailable;
        address payable organizer;
        bool isActive;
    }

    uint256 public eventCount;
    mapping(uint256 => Event) public events;
    mapping(uint256 => mapping(address => bool)) public hasTicket;

    event EventCreated(uint256 indexed id, string name, uint256 date, uint256 price, address indexed organizer);
    event TicketPurchased(uint256 indexed id, address indexed buyer);
    event EventCancelled(uint256 indexed id);

    /// @notice Create a new event
    /// @param _name Event name
    /// @param _location Event location
    /// @param _date Event date (Unix timestamp)
    /// @param _price Ticket price in wei
    /// @param _ticketsAvailable Number of tickets available
    function createEvent(
        string memory _name,
        string memory _location,
        uint256 _date,
        uint256 _price,
        uint256 _ticketsAvailable
    ) external {
        require(_date > block.timestamp, "Event date must be in the future");
        require(_ticketsAvailable > 0, "Must have at least one ticket");
        require(_price > 0, "Ticket price must be greater than zero");

        eventCount++;
        events[eventCount] = Event({
            id: eventCount,
            name: _name,
            location: _location,
            date: _date,
            price: _price,
            ticketsAvailable: _ticketsAvailable,
            organizer: payable(msg.sender),
            isActive: true
        });

        emit EventCreated(eventCount, _name, _date, _price, msg.sender);
    }

    /// @notice Purchase a ticket for an event
    /// @param _eventId ID of the event
    function buyTicket(uint256 _eventId) external payable {
        Event storage e = events[_eventId];
        require(e.isActive, "Event is not active");
        require(block.timestamp < e.date, "Event has already occurred");
        require(msg.value == e.price, "Incorrect payment amount");
        require(e.ticketsAvailable > 0, "Tickets sold out");
        require(!hasTicket[_eventId][msg.sender], "Already purchased");

        e.ticketsAvailable--;
        hasTicket[_eventId][msg.sender] = true;
        e.organizer.transfer(msg.value);

        emit TicketPurchased(_eventId, msg.sender);
    }

    /// @notice Cancel an event (only the organizer)
    /// @param _eventId ID of the event to cancel
    function cancelEvent(uint256 _eventId) external {
        Event storage e = events[_eventId];
        require(msg.sender == e.organizer, "Only organizer can cancel");
        require(e.isActive, "Already cancelled");

        e.isActive = false;
        emit EventCancelled(_eventId);
    }
}
