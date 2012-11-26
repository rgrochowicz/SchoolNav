
class Node
	constructor: (@vert, @contacts) ->
		@id = _.uniqueId("node_")


B2VecToObj = (b2) ->
	x: b2.x, y: b2.y

CalcDist = (a,b) ->
	dx = a.vert.x - b.vert.x
	dy = a.vert.y - b.vert.y
	Math.sqrt(dx*dx + dy*dy)

# {name:[[10,10]],name2:[[10,20]]}

GetNodes = (polygroup) ->
	scale = 10

	b2Vec2		= Box2D.Common.Math.b2Vec2
	b2BodyDef	= Box2D.Dynamics.b2BodyDef
	b2Body		= Box2D.Dynamics.b2Body
	b2FixtureDef	= Box2D.Dynamics.b2FixtureDef
	b2World		= Box2D.Dynamics.b2World
	b2PolygonShape	= Box2D.Collision.Shapes.b2PolygonShape
	b2CircleShape	= Box2D.Collision.Shapes.b2CircleShape
	b2WorldManifold	= Box2D.Collision.b2WorldManifold

	world = new b2World(new b2Vec2(0,0), true)
	world.DestroyBody(world.GetBodyList())

	addpoly = (id, points) ->
		points = _.initial(points,2)
		sums = _.reduce(points, (memo, num) ->
			memo[0] += parseInt(num[0])
			memo[1] += parseInt(num[1])
			return memo
		, [0,0])
		centroid = $v(sums).multiply(1/points.length)

		scaledcentroid = centroid.multiply(1/scale)
		adjustedpoints = _.map points, (p) ->
			vec = $v(p).subtract(centroid).multiply(1/scale)
			new b2Vec2(vec.x(), vec.y())

		fixDef = new b2FixtureDef()
		fixDef.shape = new b2PolygonShape()
		fixDef.density = 1
		bodyDef = new b2BodyDef()
		bodyDef.type = b2Body.b2_dynamicBody
		fixDef.shape.SetAsArray adjustedpoints
		fixDef.userData = id
		bodyDef.position.Set(scaledcentroid.x(), scaledcentroid.y())
		body = world.CreateBody bodyDef
		body.CreateFixture fixDef

	_.each(polygroup, (points, id) ->
		addpoly(id, points)
	)

	world.Step(1/60, 100, 100)
	world.ClearForces()

	nodes = []

	processcontact = (c) ->
		mani = new b2WorldManifold()

		c.GetWorldManifold(mani)

		for n in mani.m_points
			pt = n
			pt.Multiply(scale)
			node = new Node(n, [c.GetFixtureA().m_userData, c.GetFixtureB().m_userData])
			nodes.push(node)


	contact = world.GetContactList()

	processcontact(contact)
	while (contact = contact.GetNext()) != null
		processcontact(contact)

	return nodes


$ ->
	ss = $("svg").eq(0)

	cc = $("#canvas").attr(
		width: ss.width()
		height: ss.height()
	).css(position: "absolute").offset(ss.offset())
	ctx = cc[0].getContext('2d')
	ctx.strokeStyle = "#000000"
	ctx.lineWidth = 1

	applymatrix = (x,y,m) ->
		mpt = ss[0].createSVGPoint()
		mpt.x = x
		mpt.y = y
		mpt = mpt.matrixTransform m 
		x: mpt.x
		y: mpt.y

	ApplySVGMatrix = (x,y) ->
		applymatrix(x,y,ss[0].getCTM())

	polyobj = {}
	$("#navgroup path").each ->
		dnodes = $(@).attr "data-nodes"
		id = $(@).attr("id")
		tmp = []
		for sp in dnodes.split(":")
			coords = sp.split(",")
			tmp.push([coords[0],coords[1]])
		
		polyobj[id] = tmp

	nodeList = GetNodes(polyobj)
	for node in nodeList
		ma = ApplySVGMatrix(node.vert.x, node.vert.y)
		ctx.beginPath()
		ctx.arc(ma.x, ma.y, 7, 0, 2*Math.PI, false)
		ctx.fillStyle = 'green'
		ctx.fill()

	console.log nodeList


	startnode = null
	endnode = null
	$("#navgroup path").click((e) ->
		tra = applymatrix(e.clientX, e.clientY, ss[0].getScreenCTM().inverse())
		svgcoords = applymatrix(tra.x, tra.y, ss[0].getCTM())
		ctx.beginPath()
		ctx.arc(svgcoords.x, svgcoords.y, 7, 0, 2*Math.PI, false)
		ctx.fillStyle = 'green'
		ctx.fill()
		if startnode == null
			startnode = new Node(
				x:tra.x
				y:tra.y,
				[$(@).attr("id")]
			)
		else
			endnode = new Node(
				x:tra.x
				y:tra.y,
				[$(@).attr("id")]
			)

			nodeList.push(startnode, endnode)

			dist = {}
			dist[node.id] = Infinity for node in nodeList
			dist[startnode.id] = 0
			prev = {}
			prev[node.id] = null for node in nodeList


			unvisited = []
			unvisited.push node.id for node in nodeList
			unvisited = _.without(unvisited, startnode.id)

			GetNeighbors = (node) ->
				_.filter(_.filter(nodeList, (toCompare) ->
					_.intersection(node.contacts, toCompare.contacts).length > 0
				), (c) ->
					_.any(unvisited, (uv) ->
						uv == c.id and uv != node.id
					)
				)

			current = startnode

			while unvisited.length > 0
				neighbors = GetNeighbors(current)
				console.log current
				console.log neighbors
				for neighbor in neighbors
					tdist = CalcDist(current, neighbor) + dist[current.id]
					if tdist < dist[neighbor.id]
						dist[neighbor.id] = tdist
						prev[neighbor.id] = current
				unvisited = _.without(unvisited, current.id)
				closestid = _.first(_.sortBy(unvisited, (n) ->
					dist[n]
				))
				current = _.first(_.where(nodeList, {id:closestid}))

			console.log dist
			console.log prev
			console.log GetNeighbors(startnode)

			s = []
			u = endnode
			while prev[u.id] != null
				s.push(u)
				u = prev[u.id]
			s.push(startnode)
			s.reverse()

			makeline = (x,y,x1,y1) ->
				matr = ss[0].getCTM()
				#pt1 = x: x, y: y
				#pt2 = x: x1, y: y1
				pt1 = applymatrix x,y,matr
				pt2 = applymatrix x1,y1,matr
				ctx.save()
				#ctx.clearRect(0,0,cc.width(),cc.height())
				ctx.beginPath()
				ctx.moveTo pt1.x,pt1.y
				ctx.lineTo pt2.x,pt2.y
				ctx.closePath()
				ctx.stroke()
				ctx.restore()

			i = 1
			while i < s.length
				s1 = s[i-1]
				s2 = s[i]
				console.log s1.vert,s2.vert
				makeline(s1.vert.x, s1.vert.y, s2.vert.x, s2.vert.y)
				i++
			console.log s

			###startpoly = GetPolyById(startnode.parent)
			startpoly.addExtraNode(startnode)
			endpoly = GetPolyById(endnode.parent)
			endpoly.addExtraNode(endNode)
			dist = {}
			dist[node.id] = Infinity for node in GetAllNodes()
			dist[startnode.id] = 0
			unvisited = []
			unvisited.push node.id for node in GetAllNodes()
			unvisited.push endnode.id###

	)
