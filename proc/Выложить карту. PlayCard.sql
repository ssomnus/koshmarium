DROP PROCEDURE IF EXISTS PlayCard;
CREATE PROCEDURE PlayCard(tkn INT, PlayerID INT, RoomID INT, CardID INT, MonsterID INT, Part VARCHAR(10))
COMMENT "Выложить карту на поле (токен, ID игрока, ID комнаты, ID карты, ID монстра, часть тела)"
PlayCard: BEGIN
    /*Переменная для сравнения легиона*/
    DECLARE leg INT DEFAULT (SELECT Legion FROM Cards
                                JOIN CardsInGame ON Cards.ID = CardsInGame.ID_Card
                                JOIN PlayerDeck ON CardsInGame.ID = PlayerDeck.ID_Card
                                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                                JOIN Tokens ON Players.Login = Tokens.login
                                WHERE CardsInGame.ID = CardID AND ID_Player = PlayerID AND token = tkn);
    
    /*Переменная для нахождения ID карты за 1 действие*/
    DECLARE IDCard INT DEFAULT 0;

    /*Проверка на правильность ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens 
                WHERE token = tkn)
    THEN
        SELECT "Такого токена не существует" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Проверка на правильность ввода ID игрока*/
    IF NOT EXISTS (SELECT * FROM Players
                    WHERE ID = PlayerID)
    THEN
        SELECT "Такого ID игрока не существует" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms 
                    WHERE ID = RoomID)
    THEN
        SELECT "Такой комнаты не существует" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Проверка на правильность ввода ID карты*/
    IF NOT EXISTS (SELECT * FROM CardsInGame 
                    WHERE ID = CardID)
    THEN
        SELECT "Такой карты не существует" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Проверка на правильность ввода ID монстра*/
    IF NOT EXISTS (SELECT * FROM Monsters 
                    WHERE ID = MonsterID)
    THEN
        SELECT "Такого монстра не существует" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Проверка на существование карты у игрока*/
    IF EXISTS (SELECT * FROM PlayerDeck
                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE ID_Card = CardID AND ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT "У тебя нет такой карты" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Проверка на существование монстра у игрока*/
    IF NOT EXISTS (SELECT * FROM Monsters
                    JOIN Players ON Monsters.ID_Player = Players.ID
                    JOIN Tokens ON Players.Login = Tokens.login
                    WHERE Monsters.ID = MonsterID AND ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT "У тебя нет такого монстра" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Является ли игрок текущим ходящим*/
    IF NOT EXISTS (SELECT * FROM Moves 
                    JOIN Players ON Moves.ID_Player = Players.ID
                    JOIN Tokens ON Players.Login = Tokens.login
                    WHERE ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT "Сейчас не твой ход" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Нет неразыгранных способностей монстра*/
    IF EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
                JOIN Players ON Monsters.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE AbilityIsBeingUsed = "NO"
                GROUP BY ID_Monster
                HAVING cnt = 3 AND ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT "Способности монстра еще не разыграны" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Не выбираются карты для сброса*/
    IF EXISTS (SELECT * FROM PlayerDeck
                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE CardIsDiscarded = "YES" AND ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT "Выбираются карты для сброса" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Есть ли у карты эта часть тела*/
    IF NOT EXISTS (SELECT * FROM BodyPartsOfCard
                    JOIN CardsInGame ON BodyPartsOfCard.ID_Card = CardsInGame.ID_Card
                    JOIN PlayerDeck ON CardsInGame.ID = PlayerDeck.ID_Card
                    WHERE PlayerDeck.ID_Card = CardID AND Part = PartName)
    THEN
        SELECT "У этой карты нет такой части тела" AS Error;
        LEAVE PlayCard;
    END IF;

    /*Можно ли выложить карту по части тела*/
    IF Part = "Ноги"
    THEN
        IF NOT EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                        GROUP BY ID_Monster
                        HAVING ID_Monster = MonsterID AND cnt = 0)
        THEN
            SELECT "Эту карту нельзя выложить. Попробуйте положить в другого монстра или выберите другую карту" AS Error;
            LEAVE PlayCard;
        END IF;
    ELSE
        IF Part = "Туловище"
        THEN
            IF NOT EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                            GROUP BY ID_Monster
                            HAVING ID_Monster = MonsterID AND cnt = 1)
            THEN
                SELECT "Эту карту нельзя выложить. Попробуйте положить в другого монстра или выберите другую карту" AS Error;
                LEAVE PlayCard;
            END IF;
        ELSE
            IF Part = "Голова"
            THEN
                IF NOT EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                                GROUP BY ID_Monster
                                HAVING ID_Monster = MonsterID AND cnt = 2)
                THEN
                    SELECT "Эту карту нельзя выложить. Попробуйте положить в другого монстра или выберите другую карту" AS Error;
                    LEAVE PlayCard;
                END IF;
            END IF;
        END IF;
    END IF;

    /*Если это 1 действие за ход*/
    IF EXISTS (SELECT * FROM Moves
                JOIN Players ON Moves.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE RemainingSteps = 2 AND ID = PlayerID AND token = tkn)
    THEN
        /*Добавить в таблицу CardsFirstStep ID этой карты*/
        INSERT INTO CardsFirstStep(ID_Card) VALUES (CardID);

        /*Добавить карту в таблицу MonsterCards*/
        INSERT INTO MonsterCards(ID_CardInGame, ID_Monster, AbilityIsBeingUsed) VALUES(CardID, MonsterID, "NO");

        /*Изменить оставшееся количество действий*/
        UPDATE Moves
            JOIN Players ON Moves.ID_Player = Players.ID
            JOIN Tokens ON Players.Login = Tokens.login
            SET RemainingSteps = 1
            WHERE ID_Player = PlayerID AND token = tkn;
            
    /*Иначе это 2 действие за ход*/
    ELSE
        /*Проверка, было ли первое действие за ход тоже выложить карту*/
        IF EXISTS (SELECT * FROM CardsFirstStep
                    JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                    JOIN Players ON PlayerDeck.ID_Player = Players.ID
                    JOIN Tokens ON Players.Login = Tokens.login
                    WHERE ID_Player = PlayerID AND token = tkn)
        THEN
            /*Проверка, не та же самая это карта, что и в 1 действии*/
            IF NOT EXISTS (SELECT * FROM CardsFirstStep
                        JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                        JOIN Players ON PlayerDeck.ID_Player = Players.ID
                        JOIN Tokens ON Players.Login = Tokens.login
                        WHERE CardsFirstStep.ID_Card = CardID AND ID_Player = PlayerID AND token = tkn)
            THEN
                /*Узнаем ее значение*/
                SET IDCard = (SELECT ID_Card FROM CardsFirstStep
                                JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                                JOIN Players ON PlayerDeck.ID_Player = Players.ID
                                JOIN Tokens ON Players.Login = Tokens.login
                                WHERE ID_Player = PlayerID AND token = tkn);

                /*Проверка на совпадение легиона*/
                IF EXISTS (SELECT * FROM CardsFirstStep
                            JOIN CardsInGame ON CardsFirstStep.ID_Card = CardsInGame.ID
                            JOIN Cards ON CardsInGame.ID_Card = Cards.ID
                            JOIN PlayerDeck ON CardsInGame.ID = PlayerDeck.ID_Card
                            JOIN Players ON PlayerDeck.ID_Player = Players.ID
                            JOIN Tokens ON Players.Login = Tokens.login
                            WHERE Legion = leg AND ID_Player = PlayerID AND token = tkn)
                THEN
                    /*Добавить карту в таблицу MonsterCards*/
                    INSERT INTO MonsterCards(ID_CardInGame, ID_Monster, AbilityIsBeingUsed) VALUES(CardID, MonsterID, "NO");

                    /*Удаляем из таблицы CardsFirstStep карту, которая там была*/
                    DELETE CardsFirstStep FROM CardsFirstStep
                        JOIN PlayerDeck ON CardsFirstStep.ID_Card = PlayerDeck.ID_Card
                        JOIN Players ON PlayerDeck.ID_Player = Players.ID
                        JOIN Tokens ON Players.Login = Tokens.login
                        WHERE ID_Card = IDCard AND ID_Player = PlayerID AND token = tkn;

                    /*Удаляем эту карту из таблицы PlayerDeck*/
                    DELETE PlayerDeck FROM PlayerDeck
                        JOIN Players ON PlayerDeck.ID_Player = Players.ID
                        JOIN Tokens ON Players.Login = Tokens.login
                        WHERE ID_Card = IDCard AND ID_Player = PlayerID AND token = tkn;

                    /*Изменить оставшееся количество действий*/
                    UPDATE Moves
                        JOIN Players ON Moves.ID_Player = Players.ID
                        JOIN Tokens ON Players.Login = Tokens.login
                        SET RemainingSteps = 0
                        WHERE ID_Player = PlayerID AND token = tkn;
                ELSE
                    SELECT "Легион карт не совпадает" AS Error;
                    LEAVE PlayCard;
                END IF;
            ELSE
                SELECT "Этой картой нельзя походить" AS Error;
                LEAVE PlayCard;
            END IF;
        END IF;
    END IF;

    /*Проверка на завершение монстра*/
    IF EXISTS (SELECT COUNT(ID_CardInGame) AS cnt FROM MonsterCards
                GROUP BY ID_Monster
                HAVING ID_Monster = MonsterID AND cnt = 3)
    THEN
        CALL ActivationAbility();
    END IF;
END;