DROP PROCEDURE IF EXISTS CreateRoom;
CREATE PROCEDURE CreateRoom (tkn INT, Seats INT, TimeStep INT)
COMMENT "Создание комнаты (токен, количество мест, время на ход)"
CreateRoom: BEGIN
	/*Переменная для автоматически созданного ID комнаты*/
	DECLARE RoomID INT;

	DECLARE rnumb INT;

	/*Переменная для переноса ID игрока*/
    DECLARE PlayerID INT;

	/*Переменная для определения логина*/
    DECLARE lg VARCHAR(30) DEFAULT(SELECT login FROM Tokens
                                    WHERE token = tkn);
	
	/*Проверка правильности вводимости мест (от 2 до 4)*/
	IF Seats IS NULL OR Seats NOT BETWEEN 2 AND 4
	THEN
		SELECT "Недопустимое количество мест. В комнате может быть от 2 до 4 игроков" AS Error;
		LEAVE CreateRoom;
	END IF;

	/*Проверка на правильность вводимости времени*/
	IF TimeStep IS NULL OR TimeStep NOT BETWEEN 60 AND 86400
	THEN
		SELECT "Недопустимое количество времени на ход. Значение должно составлять от 60 секунд до 24 часов" AS Error;
		LEAVE CreateRoom;
	END IF;

	/*Добавить вводимые данные в таблицу Rooms*/
	INSERT IGNORE INTO Rooms(ID, MaxSeats, TimeToStep) VALUES(NULL, Seats, TimeStep);

	/*Переносим ID комнаты во временную переменную*/
	SET RoomID = LAST_INSERT_ID();

	/*Добавить колоду на комнату*/
	INSERT INTO CardsInGame(ID, ID_Card) SELECT NULL, ID FROM Cards
		ORDER BY RAND();

	SET rnumb = ROW_COUNT();

	INSERT INTO CommonDeck(ID_CardInGame, ID_Room) SELECT ID, RoomID FROM CardsInGame
		WHERE ID >= LAST_INSERT_ID()
		ORDER BY ID
		LIMIT rnumb;
	
	/*Вывести инфу о созданной комнате*/
	SELECT * FROM Rooms
		WHERE ID = RoomID;

	/*Добавление игрока в таблицу Players*/
    INSERT INTO Players(ID, Login, ID_Room, SeatNumber) VALUES(NULL, lg, RoomID, 1);
	SET PlayerID = LAST_INSERT_ID();

	/*Вывод ID игрока*/
    SELECT ID AS ID_Player FROM Players
        WHERE ID = PlayerID;

	/*Добавление 5 стартовых карт игроку в таблицу PlayerDeck*/
    INSERT INTO PlayerDeck(ID_Card, ID_Player, CardIsDiscarded) SELECT ID_CardInGame, PlayerID, "NO" FROM CommonDeck
        WHERE ID_Room = RoomID
        ORDER BY ID_CardInGame
        LIMIT 5;

    /*Удаление этих карт из таблицы CommonDeck*/
    DELETE CommonDeck FROM CommonDeck 
        JOIN PlayerDeck ON CommonDeck.ID_CardInGame = PlayerDeck.ID_Card 
        WHERE ID_CardInGame = ID_Card;
END;