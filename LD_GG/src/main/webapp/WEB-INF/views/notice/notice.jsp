<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>공지사항</title>
<!-- jQuery library -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<!-- jqGrid CSS -->
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/free-jqgrid/4.15.5/css/ui.jqgrid.min.css">
<!-- jqGrid JS -->
<script src="https://cdnjs.cloudflare.com/ajax/libs/free-jqgrid/4.15.5/jquery.jqgrid.min.js"></script>
</head>
<body>
<h1>공지사항</h1>

<div>
	<div class="grid full-height full-height-strict">
		<table id="grid" class="full-size-jq-grid"></table>
	</div>
	<div id="pager" style="height: 35px;"></div>
	
	<a href="/userinterface/notice/write">작성</a>

	<input type="text" id="keyword" name="keyword">
<!-- 	<input type="button" id="search">
 -->	<button id='search'>검색</button>
 
<span id="msg" style="display:none;">${msg}</span>

<script type="text/javascript">

const msg = document.getElementById("msg").innerHTML
if(msg){
	alert(msg)
}

// 공지 목록
$("#grid").jqGrid({
	url : "/userinterface/notice/histroy.json",
	datatype : "json",
	colNames : ['번호', '제목', '내용', '조회수', '추천 수', '날짜'],
	colModel:[
		{name:'t_b_num', index:'t_b_num', width:90, align: "center", key:true},
		{name:'t_b_title', index:'t_b_title', width:90, align: "center", sortable : false},
		{name:'t_b_content', index:'t_b_content', width:90, align: "center", sortable : false},
		{name:'t_b_views', index:'t_b_views', width:90, align: "center"},
		{name:'t_b_recom', index:'t_b_recom', width:90, align: "center"},
		{name:'t_b_date', index:'t_b_date', width:90, align: "center"}
		],
	sortable : true,
	loadonce : true,
 	autowidth: true,
	multiselect: true,
	pager:'#pager',
	rowNum: 10,
	rowList: [10, 20, 50],
	sortname: 'date',
	sortorder: 'desc',
	height: 250,
	onSelectRow: function(rowid){
		location.href = `/userinterface/notice/detail?t_b_num=\${rowid}`
	}
})
// 목록 끝

// 검색
document.getElementById("search").addEventListener("click", function() {
	let keyword = document.getElementById('keyword').value;
	console.log(keyword);
	$("#grid").jqGrid('setGridParam', {
		url : "/userinterface/notice/search.json",
		datatype : "json",
		postData: {keyword: keyword},
		colNames : ['번호', '제목', '내용', '조회수', '추천 수', '날짜'],
		colModel:[
			{name:'t_b_num', index:'t_b_num', width:90, align: "center", key:true},
			{name:'t_b_title', index:'t_b_title', width:90, align: "center", sortable : false},
			{name:'t_b_content', index:'t_b_content', width:90, align: "center", sortable : false},
			{name:'t_b_views', index:'t_b_views', width:90, align: "center"},
			{name:'t_b_recom', index:'t_b_recom', width:90, align: "center"},
			{name:'t_b_date', index:'t_b_date', width:90, align: "center"}
			],
		autowidth: true,
/* 		multiselect: true,
 */		pager:'#pager',
		rowNum: 10,
		rowList: [10, 20, 50],
		sortname: 'date',
		sortorder: 'desc',
		height: 250, 
		onSelectRow: function(rowid){
			location.href = `/userinterface/notice/detail?t_b_num=\${rowid}`
		}
	}).trigger("reloadGrid");
	console.log('jq 끝')
});
//검색 끝

</script>
</div>
</body>
</html>