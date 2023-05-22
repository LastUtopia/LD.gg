package com.ld.gg.dto.champ;

import org.apache.ibatis.type.Alias;

import lombok.Data;
import lombok.experimental.Accessors;

@Data
@Accessors(chain=true)
@Alias("champ_match_up")
public class Champ_match_up_default {
	private int champion_id;  // left_champion
	private String champion_name;
	private int enemy_champ_id; // right_champion
	private String enemy_champ;
	
//	상속 문제 발생시 한번 더 나눌 것	
	private double match_up_win_rate;
	private double match_up_cnt;
	private String team_position;
}
