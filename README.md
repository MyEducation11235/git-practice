# $\mathbb{\color[RGB]{255,60,0}{Устройство \ для \ устранения \ наводнений}}$

&emsp;&emsp;Под трубами на полу помещены датчики воды. Водопроводные краны с электрическим управлением перекрывают воду в квартире при обнаружении протечки.

## $\mathbb{\color[RGB]{255,90,0}{Основная \ информация}}$

### $\mathbb{\color[RGB]{255,127,0}{Стек \ технологий \ разработки}}$

- $\mathbb{\color[RGB]{252,193,83}{C++}}$ --- прога для микроконтроллера Arduino NANO
	+ Красивое $\mathbb{\color[RGB]{252,193,83}{ООП}}$.
	+ $\mathbb{\color[RGB]{252,193,83}{WatchDog}}$.
- $\mathbb{\color[RGB]{252,193,83}{Схемотехника}}$
	+ Создание датчика воды $\mathbb{\color[RGB]{252,193,83}{своими \ руками}}$.
	+ Проектирование [схемы](https://www.tinkercad.com/things/8X2s7huZZ8c-powerful-jarv-inari?sharecode=FLYuBVjGFrxY9XvGK_DYXVKlEWSpgqDJgoU0zU9iTNA) в $\mathbb{\color[RGB]{252,193,83}{TinkerCad}}$.

### $\mathbb{\color[RGB]{255,127,0}{Среда \ разработки}}$

- Arduino IDE

### $\mathbb{\color[RGB]{255,127,0}{Реализация \ датчика}}$

&emsp;&emsp;Два провода, расположенные довольно близко друг к другу, но не замкнутые. Если на датчик попадает вода, цепь замыкается, и мы это отслеживаем.

[<img src="Info/sensor.jpg" width="250"/>](Info/sensor.jpg)

### $\mathbb{\color[RGB]{255,127,0}{Корпус}}$

Arduino NANO управляет всем. В корпусе расположены:
1. Индикаторы в виде светодиодов.
1. Кнопка для ручного отключения\\включения воды.
1. Реле для управления высоковольтными кранами.
1. Пищалка для оповещения о протечке.
1. и ещё по мелочи (транзистор, сопротивления).

[<img src="Info/case_is_outside.jpg" width="300"/>](Info/case_is_outside.jpg)
[<img src="Info/case_is_from_the_inside.jpg" width="450"/>](Info/case_is_from_the_inside.jpg)

### $\mathbb{\color[RGB]{255,127,0}{Кран}}$

[<img src="Info/valve.jpg" width="250"/>](Info/valve.jpg)

## $\mathbb{\color[RGB]{255,90,0}{Дата}}$

&emsp;&emsp; $\mathbb{\color[RGB]{252,193,83}{Ноябрь \ 2023г.}}$

## $\mathbb{\color[RGB]{255,90,0}{Заключение}}$

&emsp;&emsp;Система отлично работает, и уже $\mathbb{\color[RGB]{252,193,83}{два \ раза}}$ из двух $\mathbb{\color[RGB]{252,193,83}{успешно \ оповестила}}$ нас о протечке и отключила воду. 
 