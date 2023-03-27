DROP PROCEDURE IF EXISTS CreateRoom;
CREATE PROCEDURE CreateRoom (Seats INT, TimeStep INT)
COMMENT "Создание комнаты (количество мест, время на ход)"
CreateRoom: BEGIN
	/*Переменная для автоматически созданного ID комнаты*/
	DECLARE RoomID INT;

	/*Проверка правильности вводимости мест (от 2 до 5)*/
	IF Seats IS NULL OR Seats NOT BETWEEN 2 AND 5
	THEN
		SELECT "Недопустимое количество мест. В комнате может быть от 2 до 5 игроков" AS Error;
		LEAVE CreateRoom;
	END IF;

	/*Проверка на правильность вводимости времени*/
	IF TimeStep IS NULL OR TimeStep < 60
	THEN
		SELECT "Недопустимое количество времени на ход. Значение должно составлять 60 секунд и больше" AS Error;
		LEAVE CreateRoom;
	END IF;

	/*Добавить вводимые данные в таблицу Rooms*/
	INSERT IGNORE INTO Rooms(ID, MaxSeats, TimeToStep) VALUES(NULL, Seats, TimeStep);

	/*Переносим ID комнаты во временную переменную*/
	SET RoomID = LAST_INSERT_ID();

	/*Добавить колоду на комнату*/
	INSERT INTO CardsInGame(ID, ID_Card) SELECT NULL, ID FROM Cards
		ORDER BY RAND();

	INSERT INTO CommonDeck(ID_CardInGame, ID_Room) SELECT ID, RoomID FROM CardsInGame
		ORDER BY RAND();

	/*Вывести инфу о созданной комнате*/
	SELECT * FROM Rooms
		WHERE ID = RoomID;
END;