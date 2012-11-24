$ ->
	$.ajax(
		url: "/processed.svg"
		dataType: "text"
	).success (s) ->
		$("#svgbeforecontainer").append(s)
		$("#svgsrcbeforecontainer").text(vkbeautify.xml(s))

		svgo = $(s).appendTo("html")

		svgo.find("path").each(() ->
			newd = applyTransforms(@, $(@).parents("svg")[0])
			$(@).attr("d", newd)
			if($(@).attr("fill") == "#e0e0e0")
				$("#navgroup", svgo).append($(@).remove())
			else
				$("#pathgroup", svgo).append($(@).remove())
		)

		svgo.remove().appendTo("#svgaftercontainer")
		$("#svgsrcaftercontainer").text(vkbeautify.xml($("#svgaftercontainer").html()))
		prettyPrint()

		$("#submit").click () ->
			$("#svgxml").val($("#svgaftercontainer").html())
			$("form").submit()
