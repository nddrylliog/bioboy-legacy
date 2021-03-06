
import ldkit/[Engine, Dead, Math, Sprites, UI, Actor, Input, Collision, Pass, Colors]
import Level, Block, Hero, Power

Explosion: class extends Actor {

    engine: Engine
    pass: Pass

    sprite: ImageSprite

    counter := 0
    maxCounter := 10

    alive := true

    init: func (=engine, =pass, pos: Vec2, image: String) {
	sprite = ImageSprite new(pos, "assets/png/%s.png" format(image))
	sprite center!()

	engine add(this)
	pass addSprite(sprite)
	update(0)
    }

    update: func (delta: Float) -> Bool {
	counter += 1

	sprite alpha = 0.8 + ((maxCounter - counter) / (1.0 * maxCounter) * 0.2)

	scale := 0.3 + (counter) / (1.0 * maxCounter) * 1
	sprite scale set!(scale, scale)
	sprite center!()

	if (counter >= maxCounter) {
	    destroy()
	}

	!alive
    }

    destroy: func {
	pass removeSprite(sprite)
    }

    _destroy: func {
	destroy()
	alive = false
    }

}

DamageLabel: class extends Actor {

    engine: Engine
    pass: Pass

    sprite: LabelSprite

    counter := 0
    maxCounter := 100

    alive := true

    init: func (=engine, =pass, pos: Vec2, damage: Int) {
	sprite = LabelSprite new(pos, "- %d" format(damage))
	sprite fontSize = 30.0
	sprite color set!(1.0, 1.0, 1.0)

	engine add(this)
	pass addSprite(sprite)
    }

    update: func (delta: Float) -> Bool {
	counter += 1

	sprite alpha = (maxCounter - counter) / (1.0 * maxCounter)
	sprite pos add!(0, -1)

	if (counter >= maxCounter) {
	    _destroy()
	}

	!alive
    }

    destroy: func {
	pass removeSprite(sprite)
    }

    _destroy: func {
	destroy()
	alive = false
    }

}

BulletType: enum {
    BUBBLE,
    BULLET
}

Bullet: class extends Actor {

    engine: Engine
    level: Level
    ui: UI

    pos: Vec2
    dir: Vec2
    speed := 12.0

    box: Box

    sprite: ImageSprite

    type: BulletType

    alive := true

    init: func (=engine, =level, =pos, =dir) {
	engine add(this)
	ui = engine ui

	type = level hero hasPower(Power DGUN) ? BulletType BULLET : BulletType BUBBLE

	sprite = ImageSprite new(pos, "assets/png/%s.png" format(type == BulletType BUBBLE ? "bubble" : "bullet"))
	sprite offset set!(- sprite width / 2, - sprite height / 2)

	level objectPass addSprite(sprite)
	
	box = Box new(vec2(0, 0), sprite width, sprite height)

	level play("plop")
    }

    update: func (delta: Float) -> Bool {
	pos add!(dir mul(speed))
	box pos set!(pos add(sprite offset))

	for(block in level blocks) {
	    bang := box collide(block box)
	    if (bang) {
		if (block permeable) continue

		block touch(bang)

		if (type == BulletType BULLET) {
		    level play("fire")
		    Explosion new(engine, level objectPass, pos, "boom")

		    diff := level hero pos sub(level hero offset) sub(pos)
		    diff x *= 1.2

		    dist := diff norm()
		    radius := 220.0
		    recoil := 12.0

		    if (dist < radius) {
			factor := - (1.0 - dist / radius) * recoil
			level hero velX += factor * dir x
			level hero velY += factor * dir y
		    }

		    damageRadius := 60.0
		    damage := 40
		    armor := (level hero hasPower(Power ARMOR) ? 0.3 : 1.0)

		    if (dist < damageRadius) {
			totalDamage := (damageRadius - dist) / damageRadius * damage * armor
			if (totalDamage > 1.0) {

			    DamageLabel new(engine, level hudPass, level hero pos add(0, -10), totalDamage)
			    level life -= totalDamage
			}
		    }
		} else {
		    level play("plop")
		    Explosion new(engine, level objectPass, pos, "plop")
		}

		_destroy()
		break
	    }
	}

	!alive
    }

    destroy: func {
	level objectPass removeSprite(sprite)
    }

    _destroy: func {
	destroy()
	alive = false
    }

}


