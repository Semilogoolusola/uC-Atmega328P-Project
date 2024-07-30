
# uC-Atmega328P-Project: Underwater Diamond Search Game

Underwater Ruins Diamond Escape is a game implemented using an ATmega328P microcontroller programmed in AVR Assembly language. The player embarks on an adventure to locate hidden diamonds within submerged ruins. This README provides an overview of the project and instructions for setting up and playing the game.

## Table of Contents

1. [Introduction](#introduction)
2. [Hardware Requirements](#hardware-requirements)
3. [Software Requirements](#software-requirements)
4. [Setup Instructions](#setup-instructions)
5. [Game Logic](#game-logic)
6. [Key Features](#key-features)
7. [Flowchart](#flowchart)
8. [License](#license)

## Introduction

"Underwater Ruins Diamond Escape" is a game designed for the ATmega328P microcontroller. The objective is to find hidden diamonds within submerged ruins by interacting with the game screen and keyboard. The game is played on a 16-byte block display, where players receive feedback based on their attempts to locate the diamonds.

## Hardware Requirements

- ATmega328P microcontroller
- 16-byte block display
- LEDs
- Push button switches
- Resistors
- Power supply

## Software Requirements

- AVR Assembly programming environment
- AVRDUDE for uploading the program to the microcontroller
- Serial monitor (optional, for debugging)

## Setup Instructions

1. **Circuit Assembly**: Connect the ATmega328P microcontroller to the 16-byte block display, LEDs, and push button switches as per the circuit diagram provided in the project documentation.
2. **Programming**: Write the AVR Assembly code for the game and compile it using an appropriate assembler.
3. **Uploading Code**: Use AVRDUDE to upload the compiled code to the ATmega328P microcontroller.
4. **Power Up**: Connect the power supply to the circuit and power up the system.

## Game Logic

- **Game Start**: The game begins when the switch PB0 is set to high.
- **Screen Display**: The display shows the pattern "SEARCH" with a counter starting at 0.
- **Attempts**: Players have up to 5 attempts to locate the hidden diamond. The screen displays "TRY" for incorrect attempts and a "Diamond pattern" for successful attempts.
- **Timer**: The display is managed using an interrupt service routine that refreshes independently of the main game logic loop.
- **Keyboard Input**: Players use the keyboard to search for the diamond. The game logic compares the pressed key with the hidden object's location.

## Key Features

- **Independent Screen Refresh**: The screen refreshes at a frequency of 880 Hz using Timer0.
- **16-byte Block Display**: The display is divided into blocks with each block containing 7 rows and 5 columns.
- **Diamond Search**: Players interact with the game using a keyboard to search for the hidden diamond.
- **Feedback System**: Visual feedback is provided for both successful and unsuccessful attempts.



## License
For detailed information on the implementation, refer to the project report provided in the repository.
Feel free to contribute to the project by submitting issues or pull requests. For any questions or support, please contact the project maintainer.




