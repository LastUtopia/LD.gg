package com.ld.gg.controller.mentoringController;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.ld.gg.dto.mentoringdto.MentorProfileDTO;
import com.ld.gg.service.mentoringService.MentorProfileService;

@RestController
@RequestMapping("/mentoring")
public class MentorProfileRestController {
	
	@Autowired
	private MentorProfileService mtpService;
	
	@GetMapping("/find-mentor")
	public String select_all_mentor_profile() throws JsonProcessingException{
		List<MentorProfileDTO> mtpList = mtpService.select_all_mentor_profiles();
		ObjectMapper objectMapper = new ObjectMapper();
		String mtpListjson = objectMapper.writeValueAsString(mtpList);
		return mtpListjson;
	}
	
	@GetMapping("/find-mentor/{mentor_email}")
	public MentorProfileDTO select_by_email_mentor_profile(@PathVariable String mentor_email){
		MentorProfileDTO mtp = mtpService.select_by_email_mentor_profile(mentor_email);
		System.out.println(mtp);
		return null;
	}
	
	@PostMapping
	public void insert_mentor_profile(@RequestBody MentorProfileDTO mtpDto){
		System.out.println(mtpDto);
		mtpService.insert_mentor_profile(mtpDto);
	}
	
}
