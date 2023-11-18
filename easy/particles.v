// Copyright(C) 2022 Lars Pontoppidan. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module easy

import shy.lib as shy
import shy.vec
import shy.utils
import shy.particle

const default_particle_image = $embed_file('../assets/images/dot.png')

pub fn (mut e Easy) new_particle_system(psc ParticleSystemConfig) &ParticleSystem {
	assert !isnil(e.shy), 'Easy struct is not initialized'

	mut system := particle.new_system(
		Rect: psc.Rect
		pool: psc.pool
	)
	default_painter := default_particle_painter(mut e)
	default_painter_id := system.add_painter(default_painter)
	e.particle_systems << system
	return &ParticleSystem{
		shy: e.shy
		system: system
		default_painter_id: default_painter_id
		rotation: psc.rotation
		scale: psc.scale
		offset: psc.offset
	}
}

@[params]
pub struct ParticleSystemConfig {
	shy.Rect
pub mut:
	rotation f32
	scale    f32 = 1.0
	offset   vec.Vec2[f32]
	pool     u32 = 500
}

@[noinit]
pub struct ParticleSystem {
	shy.ShyStruct
mut:
	system             &particle.System
	default_painter_id int
pub mut:
	rotation f32
	scale    f32 = 1.0
	offset   vec.Vec2[f32]
}

@[inline]
pub fn (ps &ParticleSystem) draw() {
	// draw := ps.shy.draw()

	// TODO transforms on the whole system
	ps.system.draw(1.0) // NOTE doesn't support frame deltas yet, it's not a problem so far
}

@[inline]
pub fn (mut ps ParticleSystem) add(component particle.Component) {
	match component {
		particle.Emitter {
			mut group := 'default'
			if component.group != '' {
				group = component.group
			}
			shim := particle.Emitter{
				...component
				group: group
			}
			ps.system.add(shim)
		}
		else {
			ps.system.add(component)
		}
	}
}

pub fn (ps &ParticleSystem) emitter_at_index(index int) ?&particle.Emitter {
	return ps.system.emitter_at(index)
}

pub fn (ps &ParticleSystem) emitters() []&particle.Emitter {
	return ps.system.emitters()
}

@[inline]
pub fn (ps &ParticleSystem) emitters_in_groups(groups []string) []&particle.Emitter {
	return ps.system.emitters_in_groups(groups)
}

pub fn (mut ps ParticleSystem) replace_default_painter(painter particle.Painter) {
	ps.system.remove_painter_at(ps.default_painter_id)
	ps.default_painter_id = ps.system.add_painter(painter)
}

pub fn (mut e Easy) image_particle_painter(config ImageParticlePainterConfig) ImageParticlePainter {
	return ImageParticlePainter{
		...config
		easy: e
	}
}

fn default_particle_painter(mut e Easy) ImageParticlePainter {
	e.quick.load(shy.ImageOptions{
		source: easy.default_particle_image
	}) or { panic(err) }

	return e.image_particle_painter(
		source: easy.default_particle_image
		color_variation: shy.ColorVariation{0, 0, 0, 0.3}
	)
}

@[params]
pub struct ImageParticlePainterConfig {
mut:
	groups          []string  = ['default']
	color           shy.Color = shy.colors.shy.white
	color_variation shy.ColorVariation
	source          shy.AssetSource = easy.default_particle_image
}

@[noinit: 'Easy.make_image_particle_painter']
pub struct ImageParticlePainter {
	easy &Easy
mut:
	groups          []string  = ['default']
	color           shy.Color = shy.colors.shy.white
	color_variation shy.ColorVariation
	source          shy.AssetSource = easy.default_particle_image
}

fn (mut ip ImageParticlePainter) init(mut p particle.Particle) {
	p.color = ip.color
	ip.color_variation.max(1.0)
	p.color.variate(ip.color_variation)
	p.init.color = p.color
}

fn (ip &ImageParticlePainter) draw(p &particle.Particle, frame_dt f64) {
	mut color := p.color

	color.a = u8(p.init.color.a * utils.remap(p.life_time, p.init.life_time, p.end.life_time,
		1, 0))
	i := ip.easy.image(
		x: p.position.x
		y: p.position.y
		width: p.size.x
		height: p.size.y
		source: ip.source
		color: color
		rotation: p.rotation
		scale: p.scale
		origin: .center
	)
	i.draw()
}

/*
[inline]
pub fn (e &Easy) text(etc EasyTextConfig) EasyText {
	assert !isnil(e.shy), 'Easy struct is not initialized'
	return EasyText{
		...etc
		shy: e.shy
	}
}

[inline]
pub fn (q &Quick) text(etc EasyTextConfig) {
	assert !isnil(q.easy), 'Easy struct is not initialized'
	q.easy.text(etc).draw()
}
*/
