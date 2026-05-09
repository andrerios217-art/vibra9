import random
import string
from locust import HttpUser, task, between


def random_email():
    suffix = "".join(random.choices(string.ascii_lowercase + string.digits, k=10))
    return f"loadtest_{suffix}@vibra9test.com"


DIMENSIONS = [
    ("mental_1", "clareza_mental"),
    ("emocional_1", "estado_emocional"),
    ("proposito_1", "proposito_pessoal"),
    ("energia_1", "energia_diaria"),
    ("corpo_1", "corpo_habitos"),
    ("comunicacao_1", "comunicacao"),
    ("relacoes_1", "relacoes"),
    ("rotina_1", "rotina_foco"),
    ("financeiro_1", "seguranca_financeira"),
]


def make_answers():
    return [
        {"question_id": qid, "dimension": dim, "score": random.randint(1, 10)}
        for qid, dim in DIMENSIONS
    ]


class Vibra9User(HttpUser):
    wait_time = between(1, 3)
    token = None
    assessment_ids = []
    ready = False

    def on_start(self):
        email = random_email()
        password = "LoadTest@123"

        reg = self.client.post("/auth/register", json={
            "name": "Load Test",
            "email": email,
            "password": password,
            "privacy_policy_accepted": True,
            "terms_accepted": True,
        }, name="/auth/register")

        if reg.status_code == 200:
            self.token = reg.json().get("access_token")
        else:
            login = self.client.post("/auth/login", json={
                "email": email, "password": password,
            }, name="/auth/login")
            if login.status_code == 200:
                self.token = login.json().get("access_token")

        if self.token:
            for _ in range(3):
                self._do_assessment()
            self.ready = True

    def _headers(self):
        return {"Authorization": f"Bearer {self.token}"} if self.token else {}

    def _do_assessment(self):
        resp = self.client.post("/assessment",
            json={"answers": make_answers()},
            headers=self._headers(),
            name="/assessment")
        if resp.status_code == 200:
            aid = resp.json().get("assessment_id")
            if aid:
                self.assessment_ids.append(aid)

    @task(3)
    def health_check(self):
        self.client.get("/", name="/health")

    @task(5)
    def get_me(self):
        self.client.get("/me", headers=self._headers(), name="/me")

    @task(4)
    def get_questions(self):
        self.client.get("/assessment/questions",
            headers=self._headers(), name="/assessment/questions")

    @task(3)
    def create_assessment(self):
        self._do_assessment()

    @task(2)
    def get_recommendations(self):
        if not self.assessment_ids:
            return
        aid = random.choice(self.assessment_ids)
        self.client.post("/recommendations",
            json={"assessment_id": aid},
            headers=self._headers(), name="/recommendations")

    @task(2)
    def get_history(self):
        self.client.get("/history",
            headers=self._headers(), name="/history")

    @task(2)
    def get_history_with_patterns(self):
        if not self.ready:
            return
        self.client.get("/history/with-patterns",
            headers=self._headers(), name="/history/with-patterns")

    @task(1)
    def get_patterns_latest(self):
        if not self.ready:
            return
        self.client.get("/patterns/latest",
            headers=self._headers(), name="/patterns/latest")

    @task(1)
    def get_patterns_recurring(self):
        if not self.ready:
            return
        self.client.get("/patterns/recurring",
            headers=self._headers(), name="/patterns/recurring")

    @task(1)
    def get_history_detail(self):
        if not self.assessment_ids:
            return
        aid = random.choice(self.assessment_ids)
        # usa o UUID real, não a string literal
        self.client.get(f"/history/{aid}",
            headers=self._headers(), name="/history/[id]")
