#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))

# get a username
USER_PROMPT() {
  echo "Enter your username:"
  read USERNAME
}

CHECK_USER() {
  # no blank input
  if [[ -z $1 ]]
  then
    USER_PROMPT
  elif [[ ${#1} -gt 30 ]]
  then
    echo "Please enter a username less than 30 characters long."
    USER_PROMPT
  else

    USER_ID=$($PSQL "SELECT user_id FROM users WHERE username LIKE '$1'")

    if [[ -z $USER_ID ]]
    then
      NEW_USER=$($PSQL "INSERT INTO users(username, best_game) VALUES('$1', 0)")
      USER_ID=$($PSQL "SELECT user_id FROM users WHERE username LIKE '$1'")
      echo "Welcome, $1! It looks like this is your first time here."
    else
      GAMES_PLAYED=$($PSQL "SELECT COUNT(*) FROM games INNER JOIN users USING(user_id) WHERE user_id=$USER_ID")
      BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID")
      USERNAME=$($PSQL "SELECT username FROM users WHERE user_id=$USER_ID")
      echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    fi
  fi
}

START_GAME() {
  SECRET_NUMBER=$(( $RANDOM % 1000 + 1 ))
  GUESS_COUNT=0
  USER_ID=$1
  echo "Guess the secret number between 1 and 1000:"
  while read GUESS
  do
    if [[ ! $GUESS =~ ^[0-9]+$ || -z $GUESS ]]
    then
      echo "That is not an integer, guess again:"
    elif [[ $GUESS -eq $SECRET_NUMBER ]]
    then
      (( GUESS_COUNT++ ))
      PR=$($PSQL "SELECT best_game FROM users WHERE user_id=$USER_ID")
      if [[ $GUESS_COUNT -lt $PR || $PR -eq 0 ]]
      then
        NEW_PR=$($PSQL "UPDATE users SET best_game=$GUESS_COUNT WHERE user_id=$USER_ID")
      fi
      VALID_GAME=$($PSQL "INSERT INTO games(user_id, guesses) VALUES($USER_ID, $GUESS_COUNT)")
      echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
      break;
    elif [[ $GUESS -gt $SECRET_NUMBER ]]
    then
      (( GUESS_COUNT++ ))
      echo "It's lower than that, guess again:"
    elif [[ $GUESS -lt $SECRET_NUMBER ]]
    then
      (( GUESS_COUNT++ ))
      echo "It's higher than that, guess again:"
    fi
  done
}


USER_PROMPT
CHECK_USER $USERNAME
START_GAME $USER_ID
