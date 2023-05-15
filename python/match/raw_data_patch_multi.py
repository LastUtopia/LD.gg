import datetime
import random
import time
import pandas as pd
import requests
from tqdm import tqdm
import private
import my_utils as mu
import json
import multiprocessing as mp
import logging
import os
os.environ["CUDA_DEVICE_ORDER"] = "PCI_BUS_ID"
os.environ["CUDA_VISIBLE_DEVICES"] = "0"
tqdm.pandas()

riot_api_keys = private.riot_api_key_array

# 티어별 유저 이름, 이름으로 puuid, puuid로 match id
def load_summoner_names_worker(worker_id):
    api_key = riot_api_keys[worker_id]
    tier_division = [
        [['GOLD', 'IV'], ['IRON', 'IV'], ['IRON', 'III']],
        [['SILVER', 'IV'], ['IRON', 'II'], ['PLATINUM', 'II']],
        [['SILVER', 'II'], ['IRON', 'I'], ['PLATINUM', 'III']],
        [['SILVER', 'III'], ['GOLD', 'I'], ['DIAMOND', 'IV']],
        [['SILVER', 'I'], ['GOLD', 'II'], ['DIAMOND', 'I']],
        [['BRONZE', 'II'], ['BRONZE', 'III'], ['DIAMOND', 'III']],
        [['GOLD', 'III'], ['BRONZE', 'I'], ['DIAMOND', 'II']],
        [['BRONZE', 'IV'], ['PLATINUM', 'IV'], ['PLATINUM', 'I']]
    ]
    for i in tqdm(tier_division[worker_id]):
        tier = i[0]
        division = i[1]
        page_p = 1
        name_set = set()

        while True:
            try:
                url = f'https://kr.api.riotgames.com/lol/league/v4/entries/RANKED_SOLO_5x5/{tier}/{division}?page={page_p}&api_key={api_key}'
                res_p = requests.get(url).json()

                for summoner in res_p:
                    name_set.add(summoner['summonerId'])

            except Exception:
                if 'Forbidden' in res_p['status']['message']:
                    break
                print(f'suummoner names 예외 발생 {res_p["status"]["message"]}, {api_key}')
                time.sleep(20)
                continue

            if len(res_p) < 200:
                break
            page_p += 1
            break
        print('load_summoner_names END', worker_id, len(name_set))
        name_lst = list(name_set)
        match_set = set()
        for summoner_name in tqdm(name_lst[:50]):
            while True:
                index = 0
                start = 1680620400  # 최근 3패치 사용 오래 된 패치 날짜
                # 13.7 패치 4월 5일 13.8패치 4월 19일 13.9 5월 3일
                # tmp = 1683904393839
                try:

                    url = f'https://kr.api.riotgames.com/lol/summoner/v4/summoners/{summoner_name}?api_key={api_key}'
                    res = requests.get(url).json()
                    puuid = res['puuid']

                    while True:
                        try:
                            url = f'https://asia.api.riotgames.com/lol/match/v5/matches/by-puuid/{puuid}/ids?startTime={start}&type=ranked&start={index}&count=100&api_key={api_key}'
                            res = requests.get(url).json()
                            index += 100
                            match_set.update(res)
                        except:
                            print(f'{res["status"]["message"]}, {api_key}')
                            time.sleep(20)
                            continue

                        if len(res) < 10:
                            break

                except Exception as e:
                    if 'found' in res['status']['message']:
                        print(summoner_name, 'not found')
                        break

                    print(f'{e} 예외 발생, {res["status"]["message"]},{api_key}')
                    time.sleep(20)
                    continue

                break

    match_list = list(match_set)
    print('load_match_ids END', worker_id, len(match_list))
    return match_list
# 끝

# match_id, matches, timeline 폼으로 만들기
def get_match_info_worker(args):
    _match_ids, i = args
    _result = []
    api_key = riot_api_keys[i]
    tmp = set()
    random.shuffle(_match_ids)

    for match_id in tqdm(_match_ids):  # 수정점
        while True:
            try:
                get_match_url = f'https://asia.api.riotgames.com/lol/match/v5/matches/{match_id}?api_key={api_key}'
                get_match_res = requests.get(get_match_url).json()
                tmp.update(get_match_res['metadata'])

                gameversion_split = get_match_res['info']['gameVersion'].split('.')
                gameversion = float(gameversion_split[0] + '.' + gameversion_split[1])
                gameduration = get_match_res['info']['gameDuration']
                if gameversion < 13.7:
                    break
                if gameduration < 900:
                    break
            except Exception as e:
                print(f'{e} match, {get_match_res["status"]["message"]},{api_key}')
                if 'found' in get_match_res['status']['message']:
                    break
                if 'Forbidden' in get_match_res['status']['message']:
                    break
                time.sleep(20)
                continue
            try:
                get_timeline_url = f'https://asia.api.riotgames.com/lol/match/v5/matches/{match_id}/timeline?api_key={api_key}'
                get_timeline_res = requests.get(get_timeline_url).json()
                tmp.update(get_timeline_res['metadata'])
            except Exception as e:
                print(f'{e} timeline, {get_timeline_res},{api_key}')
                if 'found' in get_timeline_res['status']['message']:
                    break
                if 'Forbidden' in get_timeline_res['status']['message']:
                    break
                time.sleep(20)
                continue

            _result.append([api_key, match_id, get_match_res, get_timeline_res])
            tmp.clear()
            break

    result_df = pd.DataFrame(_result, columns=['api_key', 'match_id', 'matches', 'timeline'])
    print('get_match_info END len = ', len(result_df))
    return result_df
# 끝

def df_refine(df):
    def matches_data(df):
        match_info = df['matches']['info']
        participant_list = match_info['participants']
        team_list = match_info['teams']
        matches = {
            'gameDuration': match_info['gameDuration'],
            'gameVersion': match_info['gameVersion'],
            'participants': []
        }

        for userNum in range(len(participant_list)):
            participant_dict = {
                'kills': participant_list[userNum]['kills'],
                'deaths': participant_list[userNum]['deaths'],
                'assists': participant_list[userNum]['assists'],
                'kda': participant_list[userNum]['challenges']['kda'],
                'item0': participant_list[userNum]['item0'],
                'item1': participant_list[userNum]['item1'],
                'item2': participant_list[userNum]['item2'],
                'item3': participant_list[userNum]['item3'],
                'item4': participant_list[userNum]['item4'],
                'item5': participant_list[userNum]['item5'],
                'item6': participant_list[userNum]['item6'],
                'mythicItemUsed': participant_list[userNum]['challenges'].get('mythicItemUsed', 0),
                'defense': participant_list[userNum]['perks']['statPerks']['defense'],
                'flex': participant_list[userNum]['perks']['statPerks']['flex'],
                'offense': participant_list[userNum]['perks']['statPerks']['offense'],
                'style0': participant_list[userNum]['perks']['styles'][0]['style'],
                'perks0': [perks['perk'] for perks in participant_list[userNum]['perks']['styles'][0]['selections']],
                'style1': participant_list[userNum]['perks']['styles'][1]['style'],
                'perks1': [perks['perk'] for perks in participant_list[userNum]['perks']['styles'][1]['selections']],
                'summoner1Id': participant_list[userNum]['summoner1Id'],
                'summoner2Id': participant_list[userNum]['summoner2Id'],
                'participantId': participant_list[userNum]['participantId'],
                'totalMinionsKilled': participant_list[userNum]['totalMinionsKilled'],
                'championName': participant_list[userNum]['championName'],
                'championId': participant_list[userNum]['championId'],
                'champ_level': participant_list[userNum]['champLevel'],
                'champExperience': participant_list[userNum]['champExperience'],
                'win': participant_list[userNum]['win'],
                'total_damage_dealt': participant_list[userNum]['totalDamageDealt'],
                'totalDamageDealtToChampions': participant_list[userNum]['totalDamageDealtToChampions'],
                'damageDealtToObjectives': participant_list[userNum]['damageDealtToObjectives'],
                'totalDamageTaken': participant_list[userNum]['totalDamageTaken'],
                'inhibitorKills': participant_list[userNum]['inhibitorKills'],
                'teamPosition': participant_list[userNum]['teamPosition'],
                'teamId': participant_list[userNum]['teamId'],
                'profileIcon': participant_list[userNum]['profileIcon'],
                'puuid': participant_list[userNum]['puuid'],
                'summonerName': participant_list[userNum]['summonerName'],
                'summonerId': participant_list[userNum]['summonerId'],
                'summonerLevel': participant_list[userNum]['summonerLevel'],
                'soloKills': participant_list[userNum]['challenges']['soloKills'],
                'doubleKills': participant_list[userNum]['doubleKills'],
                'tripleKills': participant_list[userNum]['tripleKills'],
                'quadraKills': participant_list[userNum]['quadraKills'],
                'pentaKills': participant_list[userNum]['pentaKills'],
                'red_ward_placed': participant_list[userNum]['detectorWardsPlaced'],
                'sight_point': participant_list[userNum]['visionScore'],
                'total_gold': participant_list[userNum]['goldEarned'],
                'timeCCingOthers': participant_list[userNum]['timeCCingOthers']
            }
            matches['participants'].append(participant_dict)

        ban_list = []
        for team in team_list:
            for ban in team['bans']:
                ban_list.append(ban['championId'])

        matches['bans'] = ban_list

        if userNum < 4:
            team_idx = 0
        else:
            team_idx = 1

        objectives = []
        objectives.append({'baron': match_info['teams'][team_idx]['objectives']['baron']})
        objectives.append({'dragon': match_info['teams'][team_idx]['objectives']['dragon']})
        objectives.append({'riftHerald': match_info['teams'][team_idx]['objectives']['riftHerald']})
        matches['objectives'] = objectives

        return matches

    def time_line_data(df):
        time_line = {}
        for i, frame in enumerate(df['timeline']['info']['frames']):
            result = {'events': [], 'participantFrames': []}
            events = []
            for event in frame['events']:
                if event['type'] == 'SKILL_LEVEL_UP' or event['type'] == 'ITEM_PURCHASED' \
                        or event['type'] == 'BUILDING_KILL':
                    events.append(event)
            result['events'].extend(events)
            try:
                for participant in range(len(frame['participantFrames'])):
                    participant_dict = {
                        'participantId': frame['participantFrames'][f'{participant + 1}']['participantId'],
                        'level': frame['participantFrames'][f'{participant + 1}']['level'],
                        'totalGold': frame['participantFrames'][f'{participant + 1}']['totalGold'],
                        'minionsKilled': frame['participantFrames'][f'{participant + 1}']['minionsKilled'],
                        'jungleMinionsKilled': frame['participantFrames'][f'{participant + 1}']['jungleMinionsKilled'],
                    }
                    result['participantFrames'].append(participant_dict)
                time_line[i] = result
            except TypeError:
                print(f'{frame}')
        return time_line

    api_key = df['api_key']
    match_id = df['matches']['metadata']['matchId']
    matches = matches_data(df)
    time_line = time_line_data(df)

    columns = ['api_key', 'match_id', 'matches', 'time_line']
    refine_df = pd.DataFrame([[api_key, match_id, matches, time_line]], columns=columns)
    return refine_df

# insert  ######### insert 수정 #########
def insert(t, conn_):
    try:
        matches_json, timeline_json = conn_.escape_string(json.dumps(t.matches)), conn_.escape_string(json.dumps(t.time_line))
        sql_insert = (
            f"insert ignore into match_raw_patch (api_key, match_id, matches, timeline) values ({repr(t.api_key)},"
            f" {repr(t.match_id)}, '{matches_json}', '{timeline_json}')"
        )
        mu.mysql_execute(sql_insert, conn_)
    except Exception as e:
        logging.exception(f"Error occurred during insert: {e}, {t.match_id}")
# insert 끝


def main():
    run_time = int(time.time() * 1000)  # 코드 돌린 Timestamp
    now = datetime.datetime.now()
    formatted_time = now.strftime("%Y-%m-%d %H:%M")
    file_path = "/runtime.txt"  # 메모장에 저장할 파일 경로와 이름 설정 헤응
    with open(file_path, "w") as f:  # 파일 열기
        f.write(formatted_time + " " + str(run_time))  # 런타임 값을 파일에 쓰기
    f.close()  # 파일 닫기

    match_ids = set()
    with mp.Pool(processes=8) as pool:
        print('**load_summoner_names**  matches_timeline')
        for i, result in enumerate(tqdm(pool.imap(load_summoner_names_worker, range(8)))):
            match_ids.update(result)

    match_ids = list(match_ids)
    print('load_summoner_names  **get_match_info**', len(match_ids))
    match_info_output = []
    with mp.Pool(processes=8) as pool:
        chunk_size = len(match_ids)
        chunks = [match_ids[i:i + chunk_size // 8] for i in range(0, len(match_ids), chunk_size // 8)]
        for i, res in enumerate(tqdm(pool.imap(get_match_info_worker, zip(chunks, range(8))), total=len(chunks))):
            match_info_output.append(res)

    merged_df = pd.concat(match_info_output)
    print("merged_df =", len(merged_df))

    refine_df = pd.concat([df_refine(row) for _, row in tqdm(merged_df.iterrows())], ignore_index=True)
    sql_conn = mu.connect_mysql()
    refine_df.progress_apply(lambda x: insert(x, sql_conn), axis=1)
    sql_conn.commit()
    sql_conn.close()
    print('done')

if __name__ == '__main__':
    for _ in tqdm(range(24)):
        try:
            main()
        except Exception as e:
            logging.exception(f'error {e}')
            continue
        print('sleep 20')
        time.sleep(20)
