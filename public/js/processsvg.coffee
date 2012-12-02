$ ->
	$.ajax(
		url: "/processed.svg"
		dataType: "text"
	).success (s) ->
		$("#svgbeforecontainer").append(s)
		$("#svgsrcbeforecontainer").text(vkbeautify.xml(s))

		svgo = $(s).appendTo("html")
		###svgo.find("#navgroup rect").each(() ->
			x = parseInt $(@).attr("x")
			y = parseInt $(@).attr("y")
			width = parseInt $(@).attr("width")
			height = parseInt $(@).attr("height")
			points = x+","+y+":"+(x+width)+","+y+":"+(x+width)+","+(y+height)+":"+x+","+(y+height)
			@.setAttributeNS("null", "data-nodes", points)
		)###
		###
			svgo.find("path").each(() ->
					newd = applyTransforms(@, $(@).parents("svg")[0])

					$(@).attr("d", newd).removeAttr("transform")
					if($(@).attr("fill") == "#e0e0e0")
						$("#navgroup", svgo).append($(@).remove())

						sl = @.pathSegList
						dn = ""
						px = 0
						py = 0
						for segi in [0...sl.numberOfItems]
							seg = sl.getItem(segi)
							tx = 0
							ty = 0
							if seg.x
								tx = px = seg.x
							else
								tx = px
							if seg.y
								ty = py = seg.y
							else
								ty = py
							if dn != ""
								dn += ":"
							dn += tx + "," + ty


						@.setAttributeNS("null", "data-nodes", dn)
					else
						$("#pathgroup", svgo).append($(@).remove().attr("stroke-width","4"))
				)
		###
		svgo.remove().appendTo("#svgaftercontainer")
		$("#svgsrcaftercontainer").text(vkbeautify.xml($("#svgaftercontainer").html()))
		#prettyPrint()

		$("#submit").click () ->
			$("#svgxml").val($("#svgaftercontainer").html())
			$("form").submit()
