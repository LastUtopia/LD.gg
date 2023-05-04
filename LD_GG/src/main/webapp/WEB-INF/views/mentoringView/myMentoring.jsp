<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>마이멘토링</title>
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
<link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css">
</head>
<body>
	
	<h2>${member.lol_account} 회원님의 마이멘토링(멘토 전용) 페이지입니다~~</h2>
	<br>
	<h4>받은 견적서</h4>
	<div id="received_estimate"></div>
	<br>
	<h4>보낸 견적서</h4>
	<div id="sent_estimate"></div>
	<br>
	<h4>수업 신청 내역</h4>
	<div id="apply_class_history"></div>
	<br>
	<h4>수업 요청 내역</h4>
	<div id="request_class_history"></div>
	<br>
	<h4>도움이 필요한 멘티목록</h4>
	<div id="menti_list"></div>
	<br>
	<h4>내가 찜한 멘토 목록</h4>
	<div id="like_mentor_list"></div>
	<br>
	
	<!-- 모달 -->
	<div class="modal fade" id="estimateModal" tabindex="-1" aria-labelledby="estimateModalLabel" aria-hidden="true" style="display: none;">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="estimateModalLabel"></h5>
      </div>
      <div class="modal-body">
        <form id="estimateForm">
          <div class="mb-3">
            <label for="estimateContent" class="form-label">견적 내용</label>
            <textarea class="form-control" id="estimateContent" rows="5"></textarea>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close">닫기</button>
            <button type="submit" class="btn btn-primary">전송</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</div>
	
<script>
$(document).ready(function() {
	getRequestHistory();
	getSentEstimate();
	$.ajax({ //도움이 필요한 멘티 목록 가져오기
        type: "GET",
        url: "/mentor/recom-menti",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
    	success: function(data) {
    		  let mentiList = $("#menti_list");
    		  let table = $("<table>").addClass("menti-table");
    		  let header = $("<tr>").append(
    		    $("<th>").text("멘티 아이디"),
    		    $("<th>").text("배우고 싶은 포지션"),
    		    $("<th>").text("배우고 싶은 챔피언"),
    		    $("<th>").text("목표 티어"),
    		    $("<th>").text("나만의 목표")
    		  );
    		  table.append(header);
    		  for (let i = 0; i < data.length; i++) {
    		    let menti = data[i];
    		    let row = $("<tr>").append(
    		      $("<td>").text(menti.summoner_name),
    		      $("<td>").text(menti.position_to_learn),
    		      $("<td>").text(menti.champion_to_learn),
    		      $("<td>").text(menti.target_tier),
    		      $("<td>").text(menti.own_goal),
    		      $("<td>").append($("<button>").attr("class", "estimate-btn")
    		    		  .attr("id", menti.summoner_name).text("견적서 작성")
    		    ));
    		    table.append(row);
    		  }
    		  mentiList.empty().append(table);
    		  $(".estimate-btn").click(function() {
    			  let menti_summoner_name = this.id;
    			    $("#estimateModal").modal("show");
    			    $(".modal-title").attr("id",menti_summoner_name);
    			    $(".modal-title").text(menti_summoner_name+"님에게 견적서 보내기");
              });
		},
        error: function(xhr, status, error) {
            console.error(xhr.responseText);
            console.error(status);
            console.error(error);
        }
    });
	$.ajax({ //받은 견적서 목록 가져오기
        type: "GET",
        url: "/mentor/get-received-estimate",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
    	success: function(data) {
    		  let rEstList = $("#received_estimate");
    		  let table = $("<table>").addClass("rEst-table");
    		  let header = $("<tr>").append(
    		    $("<th>").text("/견적서를 보낸 멘토/"),
    		    $("<th>").text("견적 내용/"),
    		    $("<th>").text("보낸 날짜/")
    		  );
    		  table.append(header);
    		  for (let i = 0; i < data.length; i++) {
    		    let est = data[i];
    		    let row = $("<tr>").append(
    		      $("<td>").text(est.mentor_lol_account),
    		      $("<td>").text(est.estimate_info),
    		      $("<td>").text(est.estimate_date)
    		    );
    		    table.append(row);
    		  }
    		  rEstList.empty().append(table);
		},
        error: function(xhr, status, error) {
            console.error(xhr.responseText);
            console.error(status);
            console.error(error);
        }
    });
	
	$.ajax({ //수업 신청 내역 가져오기
        type: "GET",
        url: "/mentor/get-mentoring-history",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
    	success: function(data) {
    		  let myMtList = $("#apply_class_history");
    		  let table = $("<table>").addClass("myMt-table");
    		  let header = $("<tr>").append(
    		    $("<th>").text("수업 이름"),
    		    $("<th>").text("멘토 이름"),
    		    $("<th>").text("상태"),
    		    $("<th>").text("신청 날짜"),
    		    $("<th>").text("완료 날짜")
    		  );
    		  table.append(header);
    		  for (let i = 0; i < data.length; i++) {
    		    let myMt = data[i];
    		    let row = $("<tr>").append(
    		      $("<td>").text(myMt.class_name),
    		      $("<td>").text(myMt.mentor_lol_account),
    		      $("<td>").text(myMt.menti_state === 0 ? "대기중" : myMt.menti_state === 1 ? "진행중" : "수업 완료"),
    		      $("<td>").text(myMt.apply_date),
    		      $("<td>").text(myMt.done_date),
    		      myMt.menti_state === 0 ? $("<button>").addClass("cancel-btn")
    		    		  .attr("id", myMt.class_id)
    		    		  .text("신청 취소") : null,
    		      myMt.menti_state === 1 ? $("<button>").addClass("refund-btn")
    		    		  .attr("id", myMt.class_id)
    		    		  .text("환불") : null
    		    );
    		    table.append(row);
    		  }
    		  myMtList.empty().append(table);
		},
        error: function(xhr, status, error) {
            console.error(xhr.responseText);
            console.error(status);
            console.error(error);
        }
    });
	$.ajax({ //내가 찜한 멘토 가져오기
		url: "/mentor/get-like-mentor",
		type: "POST",
        contentType: "application/json; charset=utf-8",
        dataType: "json",
        data: JSON.stringify({
			email: "${member.email}"
		}),
        success: function(data) {
    		  let likeMentorList = $("#like_mentor_list");
    		  let table = $("<table>").addClass("likeMentor-table");
    		  let header = $("<tr>").append(
    		    $("<th>").text("찜한 멘토")
    		  );
    		  table.append(header);
    		  for (let i = 0; i < data.length; i++) {
    		    let like_mentor = data[i];
    		    let row = $("<tr>").append(
    		      $("<td>").text(like_mentor.mentor_lol_account),
    		      $("<button>").addClass("like-cancel-btn").text("찜 해제").on("click", function() {
    		          $(this).closest('tr').remove(); // 클릭한 버튼이 속한 행 삭제
    		          let data ={
    		        	email: "${member.email}",
		                like_mentor: ""+like_mentor.like_mentor
    		          }
    		          $.ajax({
		                    url: "/mentor/delete-like-mentor",
		                    type: "DELETE",
		                    data: JSON.stringify(data),
		                    contentType: "application/json; charset=utf-8",
		                    success: function() {
		                        alert("찜 목록에서 삭제 되었습니다.");
		                    },
		                    error: function() {
		                        alert("삭제 실패.");
		                    }
		                });
    		      })
    		    );
    		    table.append(row);
    		  }
    		  likeMentorList.empty().append(table);
		},
        error: function(xhr, status, error) {
            console.error(xhr.responseText);
            console.error(status);
            console.error(error);
        }
    });
	

	
	$(document).on('click', '.cancel-btn', function(event) { //수업 신청 취소
		let classId = $(this).attr("id");
	    let mentiEmail = "${member.email}";
	    let data ={
	    	menti_email: mentiEmail,
	    	class_id: classId
	    }
		$(this).closest('tr').remove();
		$.ajax({
            url: "/mentor/delete-mentoring-history",
            type: "DELETE",
            data: JSON.stringify(data),
            contentType: "application/json; charset=utf-8",
            success: function() {
                alert("수업 신청이 취소되었습니다");
            },
            error: function() {
                alert("수업 신청 취소 실패");
            }
        });
		
	})
	$(document).on('click', '.refund-btn', function(event) { //수업 환불
		let classId = $(this).attr("id");
	    let mentiEmail = "${member.email}";
	    let data ={
		    	menti_email: mentiEmail,
		    	class_id: classId
		    }
		$(this).closest('tr').remove();
	    $.ajax({
            url: "/mentor/refund-mentoring-history",
            type: "DELETE",
            data: JSON.stringify(data),
            contentType: "application/json; charset=utf-8",
            success: function() {
                alert("수업 환불 완료");
            },
            error: function() {
                alert("환불 실패");
            }
        });
		
	})
	$(document).on('click', '.accept-btn', function(event) { //동적으로 만들어지는 버튼에 대해서
		let mentiEmail = $(this).closest('tr').find('td:eq(0)').text();
		$.ajax({
		    type: "PUT",
		    url: "/mentor/update-mentoring-history", //수락 버튼 누를떄 멘토링 내역 수정
		    contentType: "application/json; charset=utf-8",
		    data: JSON.stringify({
		    	menti_email: mentiEmail,
		        class_id: $(this).attr("id"),
		        menti_state: 1, // 상태를 업데이트 합니다.
		    }),
		    success: function() {
		      // 성공적으로 업데이트 되었을 경우 처리할 내용을 작성합니다.
		    	getRequestHistory();
		    },
		    error: function(xhr, status, error) {
		      console.error(xhr.responseText);
		      console.error(status);
		      console.error(error);
		    }
		  });
	});
	$(document).on('click', '.done-btn', function(event) { //동적으로 만들어지는 버튼에 대해서
		let mentiEmail = ""+$(this).closest('tr').find('td:eq(0)').text();
		const date = new Date();
		const kstDate = new Date(date.getTime() + (9 * 60 * 60 * 1000)); 
		const localeTime = kstDate.toISOString();
		$.ajax({
		    type: "PUT",
		    url: "/mentor/update-mentoring-history", //수업완료 버튼 누를떄 멘토링 내역 수정
		    contentType: "application/json; charset=utf-8",
		    data: JSON.stringify({
		    	menti_email: mentiEmail,
		        class_id: $(this).attr("id"),
		        menti_state: 2, // 상태를 업데이트 합니다.
				done_date: localeTime
		    }),
		    success: function() {
		      // 성공적으로 업데이트 되었을 경우 처리할 내용
		    	getRequestHistory();
		    },
		    error: function(xhr, status, error) {
		      console.error(xhr.responseText);
		      console.error(status);
		      console.error(error);
		    }
		  });
	});
	$(".btn-close").click(()=>{ 
		$("#estimateModal").modal("hide");
	});
	  $("#estimateForm").submit(function(event) {
	    event.preventDefault();
	    let form_data = {
	    	estimate_id: null,
	    	estimate_info: $("#estimateContent").val(),
	      	mentor_email: "${member.email}",
	      	menti_email: $(".modal-title").attr("id"),
	      	menti_lol_account: null,
	      	mentor_lol_account: null,
	      	estimate_date: null
	    };
	    $.ajax({ //견적서 보내기 기능
	      type: "POST",
	      url: "/mentor/save-estimate",
	      data: JSON.stringify(form_data),
	      contentType: "application/json; charset=utf-8",
	      success: function(data) {
	        alert("견적서가 전송되었습니다.");
	        $("#estimateModal").modal("hide");
	        getSentEstimate();
	      },
	      error: function(xhr, status, error) {
	        console.error(xhr.responseText);
	        console.error(status);
	        console.error(error);
	      }
	    });
	  });
	  function getRequestHistory() {
			$.ajax({ //수업 요청 내역 가져오기
		        type: "GET",
		        url: "/mentor/get-request-history",
		        contentType: "application/json; charset=utf-8",
		        dataType: "json",
		    	success: function(data) {
		    		  let myMtList = $("#request_class_history");
		    		  let table = $("<table>").addClass("myMt-table");
		    		  let header = $("<tr>").append(
		  				$("<th>").text("신청한 멘티"),
		  				$("<th>").text("수업 이름"),
		    		    $("<th>").text("상태"),
		    		    $("<th>").text("신청 날짜"),
		    		    $("<th>").text("완료 날짜")
		    		  );
		    		  table.append(header);
		    		  for (let i = 0; i < data.length; i++) {
		    			  let myMt = data[i];
		    			  let row = $("<tr>").append(
		    			    $("<td>").text(myMt.menti_lol_account),
		    			    $("<td>").text(myMt.class_name),
		    			    $("<td>").text(myMt.menti_state === 0 ? "대기중" : myMt.menti_state === 1 ? "진행중" : "수업 완료"),
		    			    $("<td>").text(myMt.apply_date),
		    			    $("<td>").text(myMt.done_date),
		    			    myMt.menti_state === 0 ? $("<button>").addClass("accept-btn")
		    			    		.attr("id", myMt.class_id)
		    			    		.text("수락") : null,
		    			    myMt.menti_state === 1 ? $("<button>").addClass("done-btn")
		    			    		.attr("id", myMt.class_id)
		    			    		.text("수업 완료") : null
		    			  );
		    		    table.append(row);
		    		  }
		    		  myMtList.empty().append(table);
				},
		        error: function(xhr, status, error) {
		            console.error(xhr.responseText);
		            console.error(status);
		            console.error(error);
		        }
		    });
			}
	  function getSentEstimate() {
	  $.ajax({ //보낸 견적서 목록 가져오기
	        type: "GET",
	        url: "/mentor/get-sent-estimate",
	        contentType: "application/json; charset=utf-8",
	        dataType: "json",
	    	success: function(data) {
	    		  let sEstList = $("#sent_estimate");
	    		  let table = $("<table>").addClass("sEst-table");
	    		  let header = $("<tr>").append(
	    		    $("<th>").text("/내 견적서를 받은 멘티/"),
	    		    $("<th>").text("견적 내용/"),
	    		    $("<th>").text("보낸 날짜/")
	    		  );
	    		  table.append(header);
	    		  for (let i = 0; i < data.length; i++) {
	    		    let est = data[i];
	    		    let row = $("<tr>").append(
	    		      $("<td>").text(est.menti_lol_account),
	    		      $("<td>").text(est.estimate_info),
	    		      $("<td>").text(est.estimate_date)
	    		    );
	    		    table.append(row);
	    		  } 
	    		  sEstList.empty().append(table);
			},
	        error: function(xhr, status, error) {
	            console.error(xhr.responseText);
	            console.error(status);
	            console.error(error);
	        }
	    });
	  }
	});
</script>


	
</body>
</html>