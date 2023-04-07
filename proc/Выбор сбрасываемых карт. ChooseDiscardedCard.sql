DROP PROCEDURE IF EXISTS ChooseDiscardedCard;
CREATE PROCEDURE ChooseDiscardedCard(tkn int(10) unsigned, PlayerID INT, CardID INT) 
COMMENT "Выбрать карты для сброса (токен, ID игрока, ID карты)"
ChooseDiscardedCard: BEGIN
      /*Проверка на правильность ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens
                    WHERE token = tkn)
    THEN
        SELECT "Такого токена не существует" AS Error;
        LEAVE ChooseDiscardedCard;
    END IF;
      
      /*Проверка на правильность ввода ID игрока*/
      IF NOT EXISTS (SELECT * FROM Players
                        WHERE ID = PlayerID)
      THEN
            SELECT "Такого ID игрока не существует" AS Error;
            LEAVE ChooseDiscardedCard;
      END IF;

      /*Проверка на правильность ввода ID карты*/
      IF NOT EXISTS (SELECT * FROM PlayerDeck
                        WHERE ID_Card = CardID)
      THEN
            SELECT "Такой карты не существует" AS Error;
            LEAVE ChooseDiscardedCard;
      END IF;

      /*Не находится ли карта в монстре*/
      IF EXISTS (SELECT * FROM MonsterCards
                  JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
                  JOIN Players ON Monsters.ID_Player = Players.ID
                  WHERE ID_CardInGame = CardID AND ID_Player = PlayerID)
      THEN
            SELECT "Эта карта находится в монстре" AS Error;
            LEAVE ChooseDiscardedCard;
      END IF;

      /*Проверка на владение карты*/
      IF NOT EXISTS (SELECT * FROM PlayerDeck
                        JOIN Players ON PlayerDeck.ID_Player = Players.ID
                        WHERE ID_Card = CardID AND ID_Player = PlayerID)
      THEN
            SELECT "У тебя нет такой карты" AS Error;
            LEAVE ChooseDiscardedCard;
      END IF;

START TRANSACTION;

      /*Выбор карт для сброса*/
      UPDATE PlayerDeck SET CardIsDiscarded = "1"
            WHERE ID_Card = CardID;

COMMIT;
      SELECT "Вы выбрали все карты для сброса? Если да, то отправьте их в сброс" AS System;
END;