# espresso-machine
Use an espresso machine to make lattes <3

# Usage
1. Download and paste to the `[resources]` directory
2. Add `ensure espresso-machine` to the cfg file or enter command `espresso-machine` in the terminal
3. Add the following line of code to `qb-core\shared\items.lua`
```
latte = { name = "latte", label = "Latte", weight = 10, type = "item", image = "latte.png", unique = false, useable = true, shouldClose = true, combinable = nil, description = "A latte to warm your soul <3" },
```
4. Add `latte.png` to `qb-inventory\html\images`

**Note**: this script requires the QBCore Framework

# Instructions
- Enter the command `espresso` on the console to spawn an espresso machine in front of you
- Look at the espresso machine and choose `Make a latte` or `Grab a latte`

# Sample Video
1. Make a latte <br />
![espresso-machine-make-latte-start](https://github.com/YohananL/espresso-machine/assets/156287601/9f2a3679-2f13-4a97-b9c2-51a322755858)
![espresso-machine-make-latte-finish](https://github.com/YohananL/espresso-machine/assets/156287601/599ffe29-4ee9-43b4-a52d-b3800173a08f)

2. Grab a latte <br />
![espresso-machine-grab-latte](https://github.com/YohananL/espresso-machine/assets/156287601/487852e7-d513-4b4b-9c43-cd88ff7b0a56)

3. Drink <br />
![espresso-machine-drink-latte](https://github.com/YohananL/espresso-machine/assets/156287601/0b946696-d73b-408d-9a4c-9c50211f5636)
