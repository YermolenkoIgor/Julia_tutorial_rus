# Julia_tutorial_rus
Введение в язык программирования Julia на русском

Julia: руководство для начинающих
* За основу используется https://github.com/JuliaComputing/JuliaBoxTutorials
* Задания для закрепления материала из http://pythontutor.ru/lessons/inout_and_arithmetic_operations/
* Еще полезной информации на русском ищите на https://habr.com/ru/hub/julia/
* Документация по языку https://docs.julialang.org/en/v1/index.html
* 1002 задачи с примерами решений на разных языках http://rosettacode.org/wiki/Category:Julia

**Julia** - высокоуровневый, высокопроизводительный язык программирования с динамической типизацией для математических вычислений. Синтаксис похож на матлабово семейство, язык написан на Си, С++ и Scheme, есть возможность вызова Сишных библиотек. 

Это весьма новый язык, и у российской аудитории пока не очень популярный. Одной из возможных причин является скудность руководств на русском языке, что мы и попытаемя исправить.

Обучалка выполнена на Jupyter, так что питонисты будут чувствовать себя как рыба в воде, ну, или питон в своих джунглях. С другой стороны, всё так просто и интерактивно, что даже у людей плохо знакомых с программированием данный материал не должен вызвать трудностей.

### Установка

С [официального сайта](https://julialang.org) скачиваем дистрибутив и устанавливаем интерпретатор Julia (*REPL*) на свой компьютер. 

Для корректной работы менеджера пакетов пользователи *Windows 7 / Windows Server 2012* также должны установить: 
* [TLS easy_fix](https://support.microsoft.com/en-us/help/3140245/update-to-enable-tls-1-1-and-tls-1-2-as-a-default-secure-protocols-in "мне помог Method 2: Microsoft Update Catalog") Чтоб узнать детали смотрите [Discourse thread](https://discourse.julialang.org/t/errors-for-git-pkg/9351 "тут всё на нерусском").
* [Windows Management Framework 3.0 or later](https://docs.microsoft.com/en-us/powershell/wmf/overview).

Процесс работы в *REPL* выглядит как-то так:

![](https://habrastorage.org/webt/gn/5u/wt/gn5uwtgsl9-jylmg8vx2--hljtk.png)


### Если проблемы при установке
* Не удается установить соединение - проверьте свои права доступа (нет ли у вас ограничений на запись в папки на C:\, зайдите как админ или запустите Джулию в режиме администратора), если используете прокси, [убедитесь](https://it-blojek.ru/nastroyka-sistemnogo-proksi-v-windows/), что оно настроено не только для браузера
* Некоторые пакеты не любят кириллицу в пути файлов, так что из-за имени пользователя на русском у меня было много проблем
* Если при работе пакета *Interact* не отображаются результаты, возможно, у Вас некорректно установлен *WebIO*, что можно исправить
```julia
#]add WebIO
using WebIO
jup = WebIO.find_jupyter_cmd()
WebIO.install_jupyter_nbextension( jup )
```
* Для корректной работы некоторых пакетов на Windows нужно чтобы пути к Julia и Jupyter были занесены в переменные среды.

![](https://habrastorage.org/webt/6f/do/c0/6fdoc0hwjk1dzyjle92qvbeallw.png)

*Компьютер/Свойства сиситемы/Дополнительные параметры системы/Переменные среды/Path* (Создать если нет) и добавить туда путь к *julia.exe*  
Пример *C:\Users\User\AppData\Local\Julia-1.2.0\bin*  
если в Path уже есть значения, то отделяем их точкой с запятой.
Теперь если в командную консоль (*cmd*) вбить `julia` то запустится интерпретатор.

После установки можно сразу приступать к работе: Вам будет доступен интерпретатор (REPL) в котором всё будет происходить в консольном режиме. 

Но нам нужен Jupyter
* [Подробно об установке](https://devpractice.ru/python-lesson-1-install/)
* [Работа с Jupyter Notebook](https://devpractice.ru/python-lesson-6-work-in-jupyter-notebook/)
* [Как настроить Jupyter Notebook для Python 3](https://tproger.ru/translations/jupyter-notebook-python-3/)
### Способ раз - малой кровью
Использовать [IJulia](https://github.com/JuliaLang/IJulia.jl). Для этого запустите *julia* и в открывшейся консоли наберите команды
```
using Pkg
Pkg.add("IJulia")
```
или
```
]add IJulia
```
затем
```
]build IJulia
```

### Способ два - всего и побольше
Вы можете установить Jupyter в комплекте [Anaconda](https://www.anaconda.com/distribution/). После установки Вам будет доступен только питон. Затем выполняйте пункт **1**, просто теперь *IJulia* не будет устанавливать Вам миниконду, а подружится с уже существующей.


Всё, теперь запускайте Jupyter либо используя ярлык в Пуск либо вбив в консоль Джулии
```
using IJulia
notebook()
```
Скачав файлы туториала, открывайте их с помощью своего Юпитера (по умолчанию в папке Downloads) и всё, можете начинать изучение!

Можно попробовать **Jupyter online**
* https://juliabox.com
* https://cocalc.com/doc/jupyter-notebook.html
* https://paiza.cloud/en/jupyter-notebook-online
## Вариант без Юпитера
- Открываете руководство здесь на гитхабе (учтите, что формулы и вёрстка здесь частенько плывёт)
- Читаете теорию и копируете примеры в Julia REPL 
- Набираете домашние задания в [Juno](https://juliacomputing.com/products/juliapro) или в [Sublime text](https://sublimetext3.ru)
