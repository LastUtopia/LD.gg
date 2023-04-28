package com.ld.gg.service;

import java.util.List;

import org.springframework.stereotype.Service;

import com.ld.gg.dao.Summoner_dao;
import com.ld.gg.dto.SummonerDto;

@Service
public class SummonerService {
	private Summoner_dao SD;

	public List<SummonerDto> get_summoner_rank() {
		List<SummonerDto> sd = SD.get_summoer_rank();
		return sd;
	}

	public List<SummonerDto> get_summoner_solo() {
		List<SummonerDto> sd = SD.get_summoer_solo();
		return sd;
	}

	public List<SummonerDto> get_summoner_flex() {
		List<SummonerDto> sd = SD.get_summoner_flex();
		return sd;
	}

	public List<SummonerDto> get_summoner_level() {
		List<SummonerDto> sd = SD.get_summoner_level();
		return sd;
	}
	

}
