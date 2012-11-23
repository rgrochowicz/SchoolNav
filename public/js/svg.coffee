
class NavPoly

	constructor: (@id, @verts) ->
		@borders = []
		@nodes = []

	addBorder: (b) ->
		@borders.push(b)
		@nodes.push(b.getNodes())

	addNodes: (n) ->
		@nodes.push(n)


	getBorders: ->
		@borders

	id: ""
	nodes: []
	verts: []

class Border

	constructor: (@polyA, @polyB, @verts) ->
		@id = Border.getNewId()
		@nodes = []
		@nodes.push(new Node(@, @verts[0], Node.TYPE_BORDER),new Node(@, @verts[1], Node.TYPE_BORDER))
		@connections = []

	#returns the poly id that is NOT the one given
	otherPoly: (str) ->
		if str == @polyB
			@polyA
		else
			@polyB

	getNodes: ->
		@nodes

	addConnection: (conn) ->
		@connections.push(conn)
		_.each(@nodes, (node) ->
			_.each(conn.getNodes(), (othernode) ->
				node.addConnection othernode
			)
		)

	id: ""
	polyA: ""
	polyB: ""
	verts: []
	nodes: []
	connections: []
	@getNewId: ->
		_.uniqueId("border_")

class Node

	#connections: array of connected polys
	#vert: x,y of node
	#type: border or added 
	constructor: (@connections, @vert, @type) ->
		@id = Node.getNewId()

	#reference to poly
	addConnection: (c) ->
		@connections.push(c)

	getConnections: ->
		@connections

	getVert: ->
		@vert

	id: ""
	vert: x: 0, y: 0
	connections: []
	@TYPE_BORDER: 1
	@TYPE_POINT: 2
	@getNewId: ->
		_.uniqueId("node_")


B2VecToObj = (b2) ->
	x: b2.x, y: b2.y

CalcDist = (a,b) ->
	dx = a.x - b.x
	dy = a.y - b.y
	Math.sqrt(dx*dx + dy*dy)

$ ->
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
	console.log world.GetBodyList()
	scale = 10

	NavPolyArray = []
	GetPolyById = (id) ->
		_.find(NavPolyArray, (p) -> p.id == id)
	BorderArray = []
	GetAllNodes = ->
		_.flatten(_.map(BorderArray, (b) ->
			b.getNodes()
		))
	ResolveConnections = ->
		_.each(NavPolyArray, (poly) ->
			_.each(poly.getBorders(), (border) ->
				_.each([GetPolyById(border.polyA),GetPolyById(border.polyB)], (adjpoly) ->
					_.each(adjpoly.getBorders(), (adjborder) ->
						if adjborder.id != border.id
							border.addConnection(adjborder)
					)
				)
			)
		)
	collarr = {}

	borderarray = []

	addpoly = (id, points) ->
		NavPolyArray.push(new NavPoly(id, points))
		#collarr[id] = []
		points = _.initial(points,2)
		poly = $p(points)
		centroid = poly.centroid_2d()
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


	$("#svgcontainer").load "processed.svg", ->
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

		$("#navgroup path").each ->
			dnodes = $(@).attr "data-nodes"
			nodes = JSON.parse dnodes
			addpoly($(@).attr("id"), nodes)
			###_.each nodes, (e,i,l) ->
				if i>0
					prev = l[i-1]
					makeline prev[0],prev[1],e[0],e[1]###

		world.Step 1/60,100,100
		world.ClearForces()

		processcontact = (c) ->
			mani = new b2WorldManifold()

			c.GetWorldManifold(mani)
			if mani.m_points.length > 0
				if mani.m_points[0].x == 0 or mani.m_points[0].y == 0
					return
				pt1 = mani.m_points[0]
				pt1.Multiply(scale)
				pt2 = mani.m_points[1]
				pt2.Multiply(scale)
				border = new Border(c.GetFixtureA().m_userData, c.GetFixtureB().m_userData, [B2VecToObj(pt1), B2VecToObj(pt2)])
				BorderArray.push(border)
				GetPolyById(c.GetFixtureA().m_userData).addBorder(border)
				GetPolyById(c.GetFixtureB().m_userData).addBorder(border)
				###

				collarr[c.GetFixtureA().m_userData].push(
					id: c.GetFixtureB().m_userData,
					pt1: pt1,
					pt2: pt2
				)
				collarr[c.GetFixtureB().m_userData].push(
					id: c.GetFixtureA().m_userData,
					pt1: pt1,
					pt2: pt2
				)
				borderarray.push(
					idA: c.GetFixtureA().m_userData,
					idB: c.GetFixtureA().m_userData,
					pt1: pt1,
					pt2: pt2
				)###


		contact = world.GetContactList()

		processcontact(contact)
		while (contact = contact.GetNext()) != null
			processcontact(contact)

		startnode = null
		endnode = null


		$("#navgroup path").each ->
			$(@).hover(() ->
				$(@).css("fill","black")
				id = $(@).attr("id")
				pp = GetPolyById(id)
				_.each(pp.getBorders(), (bor) ->
					$("#" + bor.otherPoly(id)).css("fill","red")
				)
			, () ->
				$(@).css("fill","#e0e0e0")
				id = $(@).attr("id")
				pp = GetPolyById(id)
				_.each(pp.getBorders(), (bor) ->
					$("#" + bor.otherPoly(id)).css("fill","#e0e0e0")
				)
			).click((e) ->
				tra = applymatrix(e.clientX, e.clientY, ss[0].getScreenCTM().inverse())
				svgcoords = applymatrix(tra.x, tra.y, ss[0].getCTM())
				ctx.beginPath()
				ctx.arc(svgcoords.x, svgcoords.y, 7, 0, 2*Math.PI, false)
				ctx.fillStyle = 'green'
				ctx.fill()
				if startnode == null
					startnode = new Node($(@).attr("id"),
						x:svgcoords.x
						y:svgcoords.y,
						Node.TYPE_POINT)
				else
					endnode = new Node($(@).attr("id"),
						x:svgcoords.x
						y:svgcoords.y,
						Node.TYPE_POINT)
					startpoly = GetPolyById(startnode.parent)
					startpoly.addExtraNode(startnode)
					endpoly = GetPolyById(endnode.parent)
					endpoly.addExtraNode(endNode)
					dist = {}
					dist[node.id] = Infinity for node in GetAllNodes()
					dist[startnode.id] = 0
					unvisited = []
					unvisited.push node.id for node in GetAllNodes()
					unvisited.push endnode.id

					_.each(startpoly.getBorders(), (border) ->
						_.each(border.getNodes(), (node) ->
							CalcDist(node.vert, endnode.vert)
						)
					)


			)

		ResolveConnections()

		_.each(GetAllNodes(), (node) ->
			v = node.getVert()
			tra = ApplySVGMatrix(v.x, v.y)
			ctx.beginPath()
			ctx.arc(tra.x, tra.y, 2, 0, 2*Math.PI, false)
			ctx.fillStyle = 'green'
			ctx.fill()
			console.log node.getConnections()
			_.each(node.getConnections(), (conn) -> 
				ctx.beginPath()
				ctx.moveTo(tra.x, tra.y)
				connvert = conn.getVert()
				conntra = ApplySVGMatrix(connvert.x, connvert.y)
				ctx.lineTo(conntra.x, conntra.y)
				ctx.closePath()
				ctx.stroke()
			)
		)


		#borders can access their borders and the connected nodes' borders

		###
		pt = ss[0].createSVGPoint()
		xform = $("#id1-9")[0].getScreenCTM().inverse()
		firstpos =
			x: 0
			y: 0
			obj: null
		sit = "first"
		rects = []

		findrect = (id) ->
			_.find rects, n ->
				n.id == id
		makeline = (x,y,x1,y1) ->
			ctx.save()
			#ctx.clearRect(0,0,cc.width(),cc.height())
			ctx.beginPath()
			ctx.moveTo x,y
			ctx.lineTo x1,y1
			ctx.closePath()
			ctx.stroke()
			ctx.restore()

		adjpos = (x,y) ->
			o = cc.position()
			return x: x-o.left,y: y-o.top
		applymatrix = (x,y,m) ->
			mpt = ss[0].createSVGPoint()
			mpt.x = x
			mpt.y = y
			mpt = mpt.matrixTransform m
			x: mpt.x,y: mpt.y

		$("path").filter ->
			$(@).css("fill") == "#e0e0e0"
		.each ->
			xform = @.getScreenCTM().inverse()
			bb = @.getBoundingClientRect()
			pt.x = bb.left
			pt.y = bb.top
			pt2 = pt.matrixTransform xform

			pt.x = bb.right
			pt.y = bb.bottom
			pt = pt.matrixTransform xform
			obj = document.createElementNS("http://www.w3.org/2000/svg", "rect")
			obj.setAttributeNS(null, "width", pt.x-pt2.x)
			obj.setAttributeNS(null, "height", pt.y-pt2.y)
			obj.setAttributeNS(null, "x", pt2.x)
			obj.setAttributeNS(null, "y", pt2.y)
			obj.setAttributeNS(null, "style", "fill:#ff0000")

			p = $p [[pt2.x,pt2.y],[pt.x,pt2.y],[pt.x,pt.y],[pt2.x,pt.y]]
			ctx.strokeRect pt2.x,pt2.y,5,5
			r = 
				x: pt2.x
				y: pt2.y
				width: pt.x-pt2.x
				height: pt.y-pt2.y
				obj: @
				neighbors: []
				id: @.id
				poly: p

			rects.push r
			$(obj).click (e)->
				if sit == "first"
					fp = adjpos(e.pageX,e.pageY)
					firstpos.x = fp.x
					firstpos.y = fp.y
					cent = r.poly.centroid_2d()
					fpp = applymatrix cent.x(),cent.y(),@.getScreenCTM()
					firstpos.x = fpp.x
					firstpos.y = fpp.y
					firstpos.obj = obj
					$(ss).mousemove (ev) ->
						ad = adjpos(ev.pageX,ev.pageY)
						makeline firstpos.x,firstpos.y,ad.x,ad.y

					sit = "second"
				else if sit == "second"
					second = obj

					$(ss).unbind "mousemove"
					sit = "first"
			$(obj).hover ->
				@.setAttributeNS(null, "style", "fill:#aa0000")
			,->
				@.setAttributeNS(null, "style", "fill:#ff0000")
			$(@).parent()[0].appendChild(obj)
			$(@).remove()###

