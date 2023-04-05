DROP PROCEDURE IF EXISTS StayAtRoom;
CREATE PROCEDURE StayAtRoom (tkn INT, PlayerID INT, RoomID INT)
COMMENT "Ожидание противников в комнате (токен, ID комнаты)"
StayAtRoom: BEGIN
    /*Переменная для определения места*/
    DECLARE Seat INT DEFAULT(SELECT COUNT(ID) FROM Players
                                WHERE ID_Room = RoomID);

    /*Проверка на правильность ввода токена*/
    IF NOT EXISTS (SELECT * FROM Tokens
                    WHERE token = tkn)
    THEN
        SELECT "Такого токена не существует" AS Error;
        LEAVE StayAtRoom;
    END IF;

    /*Проверка на правильность ввода ID комнаты*/
    IF NOT EXISTS (SELECT * FROM Rooms
                    WHERE ID = RoomID)
    THEN
        SELECT "Такого ID комнаты не существует" AS Error;
        LEAVE StayAtRoom;
    END IF;

    /*Проверка на правильность ввода ID игрока*/
    IF NOT EXISTS (SELECT * FROM Players
                    WHERE ID = PlayerID)
    THEN
        SELECT "Такого ID игрока не существует" AS Error;
        LEAVE StayAtRoom;
    END IF;

    /*Проверка на заполненность комнаты*/
    IF EXISTS (SELECT * FROM Players
                JOIN Rooms ON Players.ID_Room = Rooms.ID
                WHERE ID_Room = RoomID AND MaxSeats = Seat)
    THEN
        /*создаем по 5 монстров каждому игроку*/
        INSERT INTO Monsters(ID, ID_Player) VALUES(NULL, PlayerID),
                                                    (NULL, PlayerID),
                                                    (NULL, PlayerID),
                                                    (NULL, PlayerID),
                                                    (NULL, PlayerID);
        /*Определение игрока, начинающего игру*/
        SET FirstPlayer = (SELECT ID FROM Players 
                            WHERE ID_Room = RoomID AND SeatNumber = 1);

        /*Начинает ходить игрок, сидящий на 1 месте*/
        INSERT INTO Moves(ID_Player, RemainingSteps, Deadline) SELECT FirstPlayer, 2, DATE_ADD(NOW(), INTERVAL TimeToStep SECOND) FROM Rooms;
        
        /*Начинается игра*/
        CALL GameState(tkn, PlayerID, RoomID);
    ELSE
        /*Вывод всех игроков в комнате*/
        SELECT Players.ID AS ID_Player, Login, SeatNumber FROM Rooms
            JOIN Players ON Rooms.ID = Players.ID_Room
            WHERE ID_Room = RoomID;
    END IF;
END;