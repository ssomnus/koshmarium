DROP PROCEDURE IF EXISTS Tutorial;
CREATE PROCEDURE Tutorial()
Tutorial: BEGIN
    CREATE TEMPORARY TABLE Help(
        Name VARCHAR(255),
        Description VARCHAR(255)
    );

    INSERT INTO Help VALUES("Registration", "Регистрация (логин, пароль)"),
                            ("SignIn", "Вход в систему (логин, пароль)"),
                            ("AllRooms", "Вывести доступные игровые комнаты"),
                            ("CreateRoom", "Создание комнаты (количество мест, время на ход)"),
                            ("EntranceRoom", "Войти в комнату (токен, ID комнаты)"),
                            ("ExitRoom", "Выйти из комнаты (токен, ID комнаты)"),
                            ("TakeCard", "Взять карту (токен, ID игрока, ID комнаты)"),
                            ("ChooseDiscardedCard", "Выбрать карты для сброса (токен, ID игрока, ID карты)"),
                            ("DiscardAndTakeCard", "Сбросить и взять новые карты из колоды (токен, ID игрока, ID комнаты)"),
                            ("PlayCard", "Выложить карту на поле (токен, ID игрока, ID комнаты, ID карты, ID монстра, часть тела)"),
                            ("Chorister", "Использовать способность Певчий (токен, ID игрока, ID комнаты, ID карты, ID монстр)"),
                            ("Mockingbird", "Способность Пересмешник (токен, ID игрока, ID монстра, )"),
                            ("Executioner", "Способность Палач (токен, ID игрока, ID комнаты, ID карты, ID монстра)"),
                            ("Scavenger", "Способность Падальщик (токен, ID игрока, ID монстра)"),
                            ("Eater", "Способность Пожиратель (токен, ID игрока, ID карты, ID монстра)"),
                            ("GameState", "Вывести текущее состояние игры (токен, ID игрока, ID комнаты)");

    SELECT * FROM Help;
END;