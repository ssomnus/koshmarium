DROP PROCEDURE IF EXISTS GameState;
CREATE PROCEDURE GameState(tkn INT, PlayerID INT, RoomID INT)
COMMENT "Вывести текущее состояние игры (токен, ID игрока, ID комнаты)"
GameState: BEGIN
    /*Проверка на правильность ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens
                    WHERE token = tkn)
    THEN
        SELECT "Такого токена не существует" AS Error;
        LEAVE GameState;
    END IF;

    /*Проверка на правильность ввода ID игрока*/
    IF NOT EXISTS (SELECT * FROM Players 
                    WHERE ID = PlayerID)
    THEN
        SELECT "Такого ID игрока не существует" AS Error;
        LEAVE GameState;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms
                    WHERE Rooms.ID = RoomID)
    THEN
        SELECT "Такого ID комнаты не существует" AS Error;
        LEAVE GameState;
    END IF;

    /*(1)Инфо об игроках в комнате: ID, логин, номер места, количество собранных монстров*/
    SELECT Players.ID AS ID_Player, Login, SeatNumber, 
    (SELECT COUNT(Monsters.ID) FROM Monsters
        JOIN Players ON Monsters.ID_Player = Players.ID
        GROUP BY ID_Player
        HAVING ID_Room = RoomID) AS Count_Monsters
    FROM Players
        JOIN Monsters ON Players.ID = Monsters.ID_Player
        WHERE ID_Room = RoomID
        ORDER BY SeatNumber;

    /*(2)Инфо о текущем ходящем: ID, логин, время на ход, оставшееся колво действий*/
    SELECT ID_Player, Login, Deadline, RemainingSteps FROM Moves
        JOIN Players ON Moves.ID_Player = Players.ID
        WHERE ID_Room = RoomID;

    /*(3)Карта за первое действие текущего ходящего*/
    SELECT CardsFirstStep.ID_Card AS ID_Card, NameBodyPart, Legion FROM CardsFirstStep
        JOIN CardsInGame ON CardsFirstStep.ID_Card = CardsInGame.ID
        JOIN Cards ON CardsInGame.ID_Card = Cards.ID
        JOIN PlayerDeck ON CardsInGame.ID = PlayerDeck.ID_Card
        JOIN Players ON PlayerDeck.ID_Player = Players.ID
        JOIN UsedParts ON CardsInGame.ID = UsedParts.ID_Card
        WHERE ID_Room = RoomID;

    /*(4)Инфо о поле: ID монстра, из каких карт состоит монстр (легион, часть тела, способность), кому он принадлежит*/
    SELECT ID_Player, ID_Monster, ID_CardInGame, NameBodyPart, Legion, Ability FROM MonsterCards
        JOIN Monsters ON MonsterCards.ID_Monster = Monsters.ID
        JOIN Players ON Monsters.ID_Player = Players.ID
        JOIN CardsInGame ON MonsterCards.ID_CardInGame = CardsInGame.ID
        JOIN Cards ON CardsInGame.ID_Card = Cards.ID
        JOIN UsedParts ON CardsInGame.ID = UsedParts.ID_Card
        WHERE ID_Room = RoomID;

    /*(5)Вывести для игрока его колоду карт*/
    SELECT PlayerDeck.ID_Card AS ID_Card, PartName, Legion, Ability, CardIsDiscarded FROM PlayerDeck
        JOIN CardsInGame ON PlayerDeck.ID_Card = CardsInGame.ID
        JOIN Cards ON CardsInGame.ID_Card = Cards.ID /*Способность, Легион*/
        JOIN BodyPartsOfCard ON Cards.ID = BodyPartsOfCard.ID_Card /*Часть тела, сброшена ли*/
        JOIN Players ON PlayerDeck.ID_Player = Players.ID
        WHERE ID_Player = PlayerID;

    /*(6)Певчая колода для текущего игрока*/
    IF EXISTS (SELECT * FROM Moves
                JOIN Players ON Moves.ID_Player = Players.ID
                JOIN Tokens ON Players.Login = Tokens.login
                WHERE ID_Player = PlayerID AND token = tkn)
    THEN
        SELECT ChoristerDeck.ID_Card AS ID_Card, PartName, Legion, Ability, CardIsDiscarded FROM ChoristerDeck
            JOIN CardsInGame ON ChoristerDeck.ID_Card = CardsInGame.ID
            JOIN Cards ON CardsInGame.ID_Card = Cards.ID
            JOIN BodyPartsOfCard ON Cards.ID = BodyPartsOfCard.ID_Card
            JOIN PlayerDeck ON CardsInGame.ID = PlayerDeck.ID_Card
            JOIN Players ON PlayerDeck.ID_Player = Players.ID
            WHERE ID_Room = RoomID;
    END IF;
END;